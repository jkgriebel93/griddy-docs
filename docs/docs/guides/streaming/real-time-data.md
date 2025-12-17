# Real-Time Data

This guide covers strategies for getting near real-time NFL data updates using the Griddy SDK.

## Overview

While the NFL API doesn't provide true real-time streaming (WebSocket), you can achieve near real-time updates through:

- Polling live game endpoints
- Using live game stats endpoints
- Implementing smart polling strategies

## Live Game Data Endpoints

### Live Game Stats

The `get_live_game_stats` endpoint provides current game statistics:

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Get live stats for current week
live_stats = nfl.games.get_live_game_stats(
    season=2024,
    season_type="REG",
    week=1
)

for game in live_stats:
    print(f"Game: {game.game_id}")
    print(f"Status: {game.game_status}")
    print(f"Score: {game.away_score} - {game.home_score}")
```

### Polling Implementation

```python
import time
from typing import Callable, Dict, Any
from griddy.nfl import GriddyNFL

class LiveGamePoller:
    def __init__(self, nfl: GriddyNFL, poll_interval: int = 30):
        self.nfl = nfl
        self.poll_interval = poll_interval
        self._running = False
        self._callbacks: list[Callable] = []
        self._last_data: Dict[str, Any] = {}

    def add_callback(self, callback: Callable):
        """Add callback to be called on updates."""
        self._callbacks.append(callback)

    def start(self, season: int, season_type: str, week: int):
        """Start polling for live data."""
        self._running = True

        while self._running:
            try:
                games = self.nfl.games.get_games(
                    season=season,
                    season_type=season_type,
                    week=week
                )

                # Check for changes
                for game in games.games:
                    if self._has_changed(game):
                        self._notify(game)
                        self._last_data[game.id] = self._game_to_dict(game)

                time.sleep(self.poll_interval)

            except Exception as e:
                print(f"Polling error: {e}")
                time.sleep(5)  # Back off on error

    def stop(self):
        """Stop polling."""
        self._running = False

    def _has_changed(self, game) -> bool:
        """Check if game data has changed."""
        if game.id not in self._last_data:
            return True

        last = self._last_data[game.id]
        current = self._game_to_dict(game)

        return last != current

    def _game_to_dict(self, game) -> dict:
        """Convert game to comparable dict."""
        return {
            'status': game.game_status,
            'home_score': game.home_team.score,
            'away_score': game.away_team.score,
        }

    def _notify(self, game):
        """Notify all callbacks of update."""
        for callback in self._callbacks:
            try:
                callback(game)
            except Exception as e:
                print(f"Callback error: {e}")

# Usage
nfl = GriddyNFL(nfl_auth={"accessToken": "token"})
poller = LiveGamePoller(nfl, poll_interval=30)

def on_game_update(game):
    print(f"Update: {game.away_team.abbreviation} {game.away_team.score} - "
          f"{game.home_team.score} {game.home_team.abbreviation}")

poller.add_callback(on_game_update)
poller.start(season=2024, season_type="REG", week=1)
```

## Async Polling

For better performance with async applications:

```python
import asyncio
from griddy.nfl import GriddyNFL

class AsyncLiveGamePoller:
    def __init__(self, nfl: GriddyNFL, poll_interval: int = 30):
        self.nfl = nfl
        self.poll_interval = poll_interval
        self._running = False

    async def poll(self, season: int, season_type: str, week: int):
        """Async polling coroutine."""
        self._running = True
        last_data = {}

        while self._running:
            try:
                games = await self.nfl.games.get_games_async(
                    season=season,
                    season_type=season_type,
                    week=week
                )

                updates = []
                for game in games.games:
                    game_key = game.id
                    current_state = (game.game_status, game.home_team.score, game.away_team.score)

                    if game_key not in last_data or last_data[game_key] != current_state:
                        updates.append(game)
                        last_data[game_key] = current_state

                if updates:
                    yield updates

                await asyncio.sleep(self.poll_interval)

            except Exception as e:
                print(f"Error: {e}")
                await asyncio.sleep(5)

    def stop(self):
        self._running = False

# Usage
async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "token"})
    poller = AsyncLiveGamePoller(nfl, poll_interval=30)

    async for updates in poller.poll(2024, "REG", 1):
        for game in updates:
            print(f"Update: {game.id}")

asyncio.run(main())
```

## Smart Polling Strategies

### Adaptive Polling

Adjust polling frequency based on game state:

```python
def get_poll_interval(games) -> int:
    """Get optimal poll interval based on game states."""

    # Check if any games are in progress
    in_progress = any(g.game_status == "IN_PROGRESS" for g in games)

    if in_progress:
        return 15  # Poll more frequently during active games

    # Check if games are about to start (within 30 minutes)
    about_to_start = any(
        g.game_status == "SCHEDULED" and
        time_until_start(g) < 1800  # 30 minutes
        for g in games
    )

    if about_to_start:
        return 60  # Poll every minute before games start

    return 300  # Poll every 5 minutes when no games active
```

### Game State Machine

Track game state transitions:

```python
from enum import Enum

class GameState(Enum):
    SCHEDULED = "scheduled"
    STARTING = "starting"
    IN_PROGRESS = "in_progress"
    HALFTIME = "halftime"
    FINAL = "final"

class GameStateTracker:
    def __init__(self):
        self.states: Dict[str, GameState] = {}

    def update(self, game) -> tuple[GameState, GameState] | None:
        """Update game state, return (old, new) if changed."""
        game_id = game.id
        new_state = self._map_status(game.game_status)

        if game_id not in self.states:
            self.states[game_id] = new_state
            return None  # Initial state, no transition

        old_state = self.states[game_id]
        if old_state != new_state:
            self.states[game_id] = new_state
            return (old_state, new_state)

        return None

    def _map_status(self, status: str) -> GameState:
        mapping = {
            "SCHEDULED": GameState.SCHEDULED,
            "IN_PROGRESS": GameState.IN_PROGRESS,
            "HALFTIME": GameState.HALFTIME,
            "FINAL": GameState.FINAL,
            "FINAL_OVERTIME": GameState.FINAL,
        }
        return mapping.get(status, GameState.SCHEDULED)
```

## Event-Based Architecture

### Publisher-Subscriber Pattern

```python
from dataclasses import dataclass
from typing import Callable, List

@dataclass
class GameEvent:
    event_type: str  # "score_change", "status_change", "game_start", "game_end"
    game_id: str
    data: dict

class EventBus:
    def __init__(self):
        self._subscribers: Dict[str, List[Callable]] = {}

    def subscribe(self, event_type: str, callback: Callable):
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(callback)

    def publish(self, event: GameEvent):
        if event.event_type in self._subscribers:
            for callback in self._subscribers[event.event_type]:
                callback(event)

# Usage
bus = EventBus()

def on_score_change(event: GameEvent):
    print(f"Score changed in game {event.game_id}: {event.data}")

def on_game_end(event: GameEvent):
    print(f"Game {event.game_id} ended: {event.data}")

bus.subscribe("score_change", on_score_change)
bus.subscribe("game_end", on_game_end)
```

## Rate Limiting Considerations

Be mindful of API rate limits:

```python
import time
from collections import deque

class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = deque()

    def can_request(self) -> bool:
        now = time.time()

        # Remove old requests
        while self.requests and self.requests[0] < now - self.window_seconds:
            self.requests.popleft()

        return len(self.requests) < self.max_requests

    def record_request(self):
        self.requests.append(time.time())

    def wait_if_needed(self):
        while not self.can_request():
            time.sleep(0.1)
        self.record_request()

# Usage
limiter = RateLimiter(max_requests=60, window_seconds=60)

while True:
    limiter.wait_if_needed()
    games = nfl.games.get_games(...)
```

## Best Practices

1. **Don't poll too aggressively**: 15-30 seconds is usually sufficient
2. **Use adaptive polling**: Increase frequency only during active games
3. **Handle errors gracefully**: Implement backoff on failures
4. **Cache unchanged data**: Only process updates that actually changed
5. **Consider server-sent events**: For web applications, push updates to clients
6. **Monitor rate limits**: Track API usage to avoid throttling
