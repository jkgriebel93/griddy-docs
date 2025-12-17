# Rate Limiting

This guide explains how to handle API rate limits when using the Griddy SDK.

## Overview

The NFL API enforces rate limits to prevent abuse. When you exceed these limits, requests will be rejected with HTTP 429 (Too Many Requests) errors.

## Handling Rate Limit Errors

### Python

```python
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import RateLimitError, GriddyError
import time

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

def fetch_with_retry(func, max_retries=3):
    """Execute function with rate limit retry."""
    for attempt in range(max_retries):
        try:
            return func()
        except RateLimitError as e:
            if attempt < max_retries - 1:
                wait_time = e.retry_after or (2 ** attempt * 10)
                print(f"Rate limited. Waiting {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                raise

# Usage
games = fetch_with_retry(
    lambda: nfl.games.get_games(season=2024, season_type="REG", week=1)
)
```

### TypeScript

```typescript
import { GriddyNFL, GriddyNFLDefaultError } from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

async function fetchWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3
): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (error instanceof GriddyNFLDefaultError && error.statusCode === 429) {
        if (attempt < maxRetries - 1) {
          const waitTime = Math.pow(2, attempt) * 10 * 1000;
          console.log(`Rate limited. Waiting ${waitTime / 1000} seconds...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
        } else {
          throw error;
        }
      } else {
        throw error;
      }
    }
  }
  throw new Error('Max retries exceeded');
}

// Usage
const games = await fetchWithRetry(() =>
  nfl.games.getGames(2024, 'REG', 1)
);
```

## Built-in Retry Configuration

The SDK supports automatic retries with exponential backoff:

### Python

```python
from griddy.nfl import GriddyNFL
from griddy.nfl.utils.retries import RetryConfig, BackoffStrategy

# Configure retry behavior
retry_config = RetryConfig(
    strategy="backoff",
    backoff=BackoffStrategy(
        initial_interval=500,      # 500ms initial delay
        max_interval=60000,        # 60 second max delay
        exponent=1.5,              # Exponential factor
        max_elapsed_time=300000    # 5 minute max total time
    ),
    retry_connection_errors=True
)

# Apply globally
nfl = GriddyNFL(
    nfl_auth={"accessToken": "token"},
    retry_config=retry_config
)

# Or per-request
games = nfl.games.get_games(
    season=2024,
    season_type="REG",
    week=1,
    retries=retry_config
)
```

### TypeScript

```typescript
import { GriddyNFL, createRetryConfig } from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

// Per-request retry configuration
const games = await nfl.games.getGames(2024, 'REG', 1, false, {
  retries: createRetryConfig({
    maxRetries: 5,
    initialDelayMs: 1000,
    maxDelayMs: 30000,
    backoffMultiplier: 2
  })
});
```

## Rate Limiter Implementation

Proactively limit request rate to avoid hitting limits:

```python
import time
from collections import deque
from threading import Lock

class RateLimiter:
    """Token bucket rate limiter."""

    def __init__(self, requests_per_minute: int = 60):
        self.requests_per_minute = requests_per_minute
        self.window = 60  # seconds
        self.requests = deque()
        self._lock = Lock()

    def acquire(self):
        """Wait until a request can be made."""
        with self._lock:
            now = time.time()

            # Remove requests outside the window
            while self.requests and self.requests[0] < now - self.window:
                self.requests.popleft()

            # Wait if at capacity
            if len(self.requests) >= self.requests_per_minute:
                wait_time = self.requests[0] + self.window - now
                if wait_time > 0:
                    time.sleep(wait_time)

                # Clean up again after waiting
                now = time.time()
                while self.requests and self.requests[0] < now - self.window:
                    self.requests.popleft()

            self.requests.append(time.time())

# Usage
limiter = RateLimiter(requests_per_minute=60)

def rate_limited_request(func):
    """Decorator to rate limit requests."""
    limiter.acquire()
    return func()

# Apply to SDK calls
games = rate_limited_request(
    lambda: nfl.games.get_games(season=2024, season_type="REG", week=1)
)
```

## Async Rate Limiter

```python
import asyncio
from collections import deque

class AsyncRateLimiter:
    def __init__(self, requests_per_minute: int = 60):
        self.requests_per_minute = requests_per_minute
        self.window = 60
        self.requests = deque()
        self._lock = asyncio.Lock()

    async def acquire(self):
        async with self._lock:
            now = asyncio.get_event_loop().time()

            while self.requests and self.requests[0] < now - self.window:
                self.requests.popleft()

            if len(self.requests) >= self.requests_per_minute:
                wait_time = self.requests[0] + self.window - now
                if wait_time > 0:
                    await asyncio.sleep(wait_time)

                now = asyncio.get_event_loop().time()
                while self.requests and self.requests[0] < now - self.window:
                    self.requests.popleft()

            self.requests.append(asyncio.get_event_loop().time())

# Usage
limiter = AsyncRateLimiter(requests_per_minute=60)

async def get_all_weeks(nfl, season: int):
    """Fetch all weeks with rate limiting."""
    all_games = []

    for week in range(1, 19):
        await limiter.acquire()
        games = await nfl.games.get_games_async(
            season=season,
            season_type="REG",
            week=week
        )
        all_games.extend(games.games)

    return all_games
```

## Batch Requests

Reduce API calls by batching related requests:

```python
import asyncio

async def get_season_data(nfl, season: int):
    """Get all season data efficiently with rate limiting."""

    limiter = AsyncRateLimiter(requests_per_minute=60)

    async def get_week(week: int):
        await limiter.acquire()
        return await nfl.games.get_games_async(
            season=season,
            season_type="REG",
            week=week
        )

    # Fetch all weeks concurrently (rate limited)
    tasks = [get_week(week) for week in range(1, 19)]
    results = await asyncio.gather(*tasks)

    return results
```

## Best Practices

1. **Use exponential backoff**: Increase wait time with each retry
2. **Respect Retry-After headers**: Use the server's suggested wait time
3. **Implement proactive rate limiting**: Don't wait for errors
4. **Cache responses**: Reduce unnecessary API calls
5. **Batch requests**: Combine related data fetches
6. **Monitor usage**: Track your API call patterns
7. **Handle gracefully**: Never crash on rate limit errors

## Monitoring Rate Limit Usage

```python
class RateLimitMonitor:
    def __init__(self):
        self.total_requests = 0
        self.rate_limited = 0

    def record_request(self):
        self.total_requests += 1

    def record_rate_limit(self):
        self.rate_limited += 1

    def get_stats(self):
        return {
            'total_requests': self.total_requests,
            'rate_limited': self.rate_limited,
            'rate_limit_percentage': (
                self.rate_limited / self.total_requests * 100
                if self.total_requests > 0 else 0
            )
        }

monitor = RateLimitMonitor()

# Wrap SDK calls
def tracked_request(func):
    monitor.record_request()
    try:
        return func()
    except RateLimitError:
        monitor.record_rate_limit()
        raise

# Check stats periodically
print(monitor.get_stats())
```
