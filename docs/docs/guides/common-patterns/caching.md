# Caching

This guide explains caching strategies for improving performance and reducing API calls when using the Griddy SDK.

## Overview

Caching API responses can:

- Reduce API calls and avoid rate limits
- Improve application performance
- Lower bandwidth usage
- Provide offline fallback data

## Simple In-Memory Cache

### Python

```python
import time
from typing import Any, Callable, Optional
from functools import wraps

class SimpleCache:
    def __init__(self, ttl_seconds: int = 300):
        self._cache: dict = {}
        self.ttl = ttl_seconds

    def get(self, key: str) -> Optional[Any]:
        if key in self._cache:
            value, timestamp = self._cache[key]
            if time.time() - timestamp < self.ttl:
                return value
            del self._cache[key]
        return None

    def set(self, key: str, value: Any):
        self._cache[key] = (value, time.time())

    def clear(self):
        self._cache.clear()

# Usage
cache = SimpleCache(ttl_seconds=300)

def get_games_cached(nfl, season: int, season_type: str, week: int):
    cache_key = f"games:{season}:{season_type}:{week}"

    cached = cache.get(cache_key)
    if cached:
        return cached

    games = nfl.games.get_games(
        season=season,
        season_type=season_type,
        week=week
    )

    cache.set(cache_key, games)
    return games
```

### TypeScript

```typescript
interface CacheEntry<T> {
  value: T;
  timestamp: number;
}

class SimpleCache<T> {
  private cache = new Map<string, CacheEntry<T>>();
  private ttlMs: number;

  constructor(ttlSeconds = 300) {
    this.ttlMs = ttlSeconds * 1000;
  }

  get(key: string): T | undefined {
    const entry = this.cache.get(key);
    if (entry && Date.now() - entry.timestamp < this.ttlMs) {
      return entry.value;
    }
    this.cache.delete(key);
    return undefined;
  }

  set(key: string, value: T): void {
    this.cache.set(key, { value, timestamp: Date.now() });
  }

  clear(): void {
    this.cache.clear();
  }
}

// Usage
const cache = new SimpleCache<FootballGamesResponse>(300);

async function getGamesCached(
  nfl: GriddyNFL,
  season: number,
  seasonType: string,
  week: number
) {
  const cacheKey = `games:${season}:${seasonType}:${week}`;

  const cached = cache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const games = await nfl.games.getGames(season, seasonType as SeasonTypeEnum, week);
  cache.set(cacheKey, games);
  return games;
}
```

## Decorator-Based Caching

```python
from functools import wraps
import hashlib
import json

def cached(cache: SimpleCache, key_prefix: str = ""):
    """Decorator for caching function results."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function arguments
            key_parts = [key_prefix, func.__name__]
            key_parts.extend(str(arg) for arg in args)
            key_parts.extend(f"{k}={v}" for k, v in sorted(kwargs.items()))
            cache_key = ":".join(key_parts)

            # Check cache
            cached_value = cache.get(cache_key)
            if cached_value is not None:
                return cached_value

            # Call function and cache result
            result = func(*args, **kwargs)
            cache.set(cache_key, result)
            return result

        return wrapper
    return decorator

# Usage
cache = SimpleCache(ttl_seconds=300)

@cached(cache, "nfl")
def get_games(nfl, season: int, season_type: str, week: int):
    return nfl.games.get_games(
        season=season,
        season_type=season_type,
        week=week
    )
```

## TTL Strategies

Different data types warrant different cache durations:

```python
class NFLCache:
    """Cache with different TTLs for different data types."""

    def __init__(self):
        # Long TTL for historical data (doesn't change)
        self.historical = SimpleCache(ttl_seconds=86400)  # 24 hours

        # Medium TTL for standings, rosters (changes occasionally)
        self.standings = SimpleCache(ttl_seconds=3600)    # 1 hour

        # Short TTL for live data
        self.live = SimpleCache(ttl_seconds=30)           # 30 seconds

    def get_historical_game(self, nfl, game_id: str):
        """Get completed game data (long cache)."""
        cached = self.historical.get(f"game:{game_id}")
        if cached:
            return cached

        game = nfl.games.get_box_score(game_id=game_id)
        self.historical.set(f"game:{game_id}", game)
        return game

    def get_standings(self, nfl, season: int):
        """Get standings (medium cache)."""
        cached = self.standings.get(f"standings:{season}")
        if cached:
            return cached

        standings = nfl.standings.get_standings(season=season)
        self.standings.set(f"standings:{season}", standings)
        return standings

    def get_live_scores(self, nfl, season: int, season_type: str, week: int):
        """Get live game data (short cache)."""
        key = f"live:{season}:{season_type}:{week}"
        cached = self.live.get(key)
        if cached:
            return cached

        games = nfl.games.get_live_game_stats(
            season=season,
            season_type=season_type,
            week=week
        )
        self.live.set(key, games)
        return games
```

## File-Based Cache

For persistent caching across restarts:

```python
import json
import os
from pathlib import Path

class FileCache:
    def __init__(self, cache_dir: str = ".cache", ttl_seconds: int = 300):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
        self.ttl = ttl_seconds

    def _get_path(self, key: str) -> Path:
        # Sanitize key for filesystem
        safe_key = key.replace(":", "_").replace("/", "_")
        return self.cache_dir / f"{safe_key}.json"

    def get(self, key: str):
        path = self._get_path(key)

        if not path.exists():
            return None

        # Check if expired
        if time.time() - path.stat().st_mtime > self.ttl:
            path.unlink()
            return None

        try:
            with open(path) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return None

    def set(self, key: str, value):
        path = self._get_path(key)

        # Convert Pydantic models to dict
        if hasattr(value, 'model_dump'):
            value = value.model_dump()
        elif hasattr(value, 'dict'):
            value = value.dict()

        with open(path, 'w') as f:
            json.dump(value, f)

    def clear(self):
        for path in self.cache_dir.glob("*.json"):
            path.unlink()
```

## Redis Cache

For production applications with multiple instances:

```python
import redis
import json
from typing import Optional, Any

class RedisCache:
    def __init__(self, host: str = 'localhost', port: int = 6379, ttl: int = 300):
        self.client = redis.Redis(host=host, port=port, decode_responses=True)
        self.ttl = ttl

    def get(self, key: str) -> Optional[Any]:
        value = self.client.get(key)
        if value:
            return json.loads(value)
        return None

    def set(self, key: str, value: Any):
        # Convert Pydantic models
        if hasattr(value, 'model_dump'):
            value = value.model_dump()

        self.client.setex(key, self.ttl, json.dumps(value))

    def delete(self, key: str):
        self.client.delete(key)

    def clear_pattern(self, pattern: str):
        """Clear all keys matching pattern."""
        keys = self.client.keys(pattern)
        if keys:
            self.client.delete(*keys)
```

## Cache Invalidation

### Manual Invalidation

```python
class CachedNFLClient:
    def __init__(self, nfl: GriddyNFL):
        self.nfl = nfl
        self.cache = SimpleCache(ttl_seconds=300)

    def get_games(self, season: int, season_type: str, week: int):
        key = f"games:{season}:{season_type}:{week}"
        cached = self.cache.get(key)
        if cached:
            return cached

        games = self.nfl.games.get_games(
            season=season,
            season_type=season_type,
            week=week
        )
        self.cache.set(key, games)
        return games

    def invalidate_games(self, season: int, season_type: str, week: int):
        """Invalidate cache for specific games."""
        key = f"games:{season}:{season_type}:{week}"
        # Remove from cache
        if key in self.cache._cache:
            del self.cache._cache[key]

    def invalidate_all(self):
        """Clear all cached data."""
        self.cache.clear()
```

### Event-Based Invalidation

```python
class EventBasedCache:
    def __init__(self):
        self.cache = SimpleCache(ttl_seconds=3600)
        self._live_games: set = set()

    def mark_game_live(self, game_id: str):
        """Mark a game as live (don't cache)."""
        self._live_games.add(game_id)

    def mark_game_final(self, game_id: str):
        """Mark a game as final (ok to cache long-term)."""
        self._live_games.discard(game_id)

    def get_box_score(self, nfl, game_id: str):
        """Get box score with smart caching."""
        # Don't cache live games
        if game_id in self._live_games:
            return nfl.games.get_box_score(game_id=game_id)

        # Use cache for completed games
        key = f"boxscore:{game_id}"
        cached = self.cache.get(key)
        if cached:
            return cached

        result = nfl.games.get_box_score(game_id=game_id)
        self.cache.set(key, result)
        return result
```

## Best Practices

1. **Choose appropriate TTLs**: Match cache duration to data volatility
2. **Use cache keys wisely**: Include all relevant parameters in keys
3. **Handle cache misses gracefully**: Always have a fallback to fetch fresh data
4. **Serialize carefully**: Pydantic models need conversion before caching
5. **Monitor cache hit rates**: Track effectiveness of your caching strategy
6. **Clear caches on deploy**: Invalidate after code changes that affect data
7. **Consider memory limits**: Use LRU eviction for in-memory caches
