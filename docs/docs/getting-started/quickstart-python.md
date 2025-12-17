# Python Quickstart

This guide provides a comprehensive walkthrough of using the Griddy Python SDK.

## Installation

```bash
pip install griddy
```

## Basic Usage

### Initializing the Client

```python
from griddy.nfl import GriddyNFL

# With a pre-obtained token
nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

# Or with email/password (requires Playwright)
nfl = GriddyNFL(
    login_email="your_email@example.com",
    login_password="your_password",
    headless_login=True
)
```

### Getting Game Data

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

# Get games for a specific week
games = nfl.games.get_games(
    season=2024,
    season_type="REG",  # PRE, REG, or POST
    week=1
)

# Iterate through games
for game in games.games:
    print(f"Game ID: {game.id}")
    print(f"  {game.away_team.abbreviation} @ {game.home_team.abbreviation}")
    print(f"  Status: {game.game_status}")
```

### Box Scores

```python
# Get detailed box score for a game
box_score = nfl.games.get_box_score(game_id="game-uuid-here")

print(f"Home Score: {box_score.home_team_score}")
print(f"Away Score: {box_score.away_team_score}")
```

### Play-by-Play

```python
# Get play-by-play data
pbp = nfl.games.get_play_by_play(
    game_id="game-uuid-here",
    include_penalties=True,
    include_formations=False
)

for play in pbp.plays:
    print(f"Q{play.quarter} - {play.description}")
```

## Player Statistics

### Passing Stats

```python
# Get passing stats for a season
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)

for player in passing.players:
    print(f"{player.player_name}: {player.passing_yards} yards, {player.touchdowns} TDs")
```

### Rushing Stats

```python
# Get rushing stats
rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)

for player in rushing.players:
    print(f"{player.player_name}: {player.rushing_yards} yards, {player.rushing_tds} TDs")
```

### Receiving Stats

```python
# Get receiving stats
receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)

for player in receiving.players:
    print(f"{player.player_name}: {player.receptions} rec, {player.receiving_yards} yards")
```

## Next Gen Stats

```python
# Access Next Gen Stats
ngs_passing = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG"
)

# Get weekly stats
weekly_stats = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG",
    week=12
)

# Get leaderboards
fastest = nfl.ngs.leaders.get_fastest_ball_carriers(
    season=2024,
    season_type="REG",
    limit=10
)
```

## Async Support

All endpoints have async versions with the `_async` suffix:

```python
import asyncio
from griddy.nfl import GriddyNFL

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    # Use async methods
    games = await nfl.games.get_games_async(
        season=2024,
        season_type="REG",
        week=1
    )

    # Concurrent requests
    stats_tasks = [
        nfl.stats.passing.get_passing_stats_by_season_async(season=2024),
        nfl.stats.rushing.get_rushing_stats_by_season_async(season=2024),
        nfl.stats.receiving.get_receiving_stats_by_season_async(season=2024),
    ]

    passing, rushing, receiving = await asyncio.gather(*stats_tasks)

    print(f"Loaded {len(passing.players)} passers")
    print(f"Loaded {len(rushing.players)} rushers")
    print(f"Loaded {len(receiving.players)} receivers")

asyncio.run(main())
```

## Context Manager

Use the context manager for automatic cleanup:

```python
from griddy.nfl import GriddyNFL

with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)

    for game in games.games:
        print(game.id)

# HTTP client is automatically closed
```

For async usage:

```python
async with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
    games = await nfl.games.get_games_async(season=2024, season_type="REG", week=1)
```

## Error Handling

```python
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import (
    GriddyError,
    AuthenticationError,
    NotFoundError,
    RateLimitError
)

nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

try:
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)
except AuthenticationError:
    print("Token expired or invalid")
except NotFoundError as e:
    print(f"Resource not found: {e.message}")
except RateLimitError as e:
    print(f"Rate limited. Retry after: {e.retry_after} seconds")
except GriddyError as e:
    print(f"API error: {e.message} (status: {e.status_code})")
```

## Configuration Options

### Custom Timeout

```python
nfl = GriddyNFL(
    nfl_auth={"accessToken": "your_token"},
    timeout_ms=60000  # 60 seconds
)
```

### Custom Retry Configuration

```python
from griddy.nfl.utils.retries import RetryConfig, BackoffStrategy

retry_config = RetryConfig(
    strategy="backoff",
    backoff=BackoffStrategy(
        initial_interval=500,
        max_interval=60000,
        exponent=1.5,
        max_elapsed_time=300000
    ),
    retry_connection_errors=True
)

nfl = GriddyNFL(
    nfl_auth={"accessToken": "your_token"},
    retry_config=retry_config
)
```

### Per-Request Options

```python
# Override timeout for a single request
games = nfl.games.get_games(
    season=2024,
    season_type="REG",
    week=1,
    timeout_ms=30000,
    http_headers={"X-Custom-Header": "value"}
)
```

## Complete Example

```python
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError

def main():
    # Initialize client
    with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
        try:
            # Get week 1 games
            games = nfl.games.get_games(
                season=2024,
                season_type="REG",
                week=1
            )

            print(f"Found {len(games.games)} games\n")

            for game in games.games:
                home = game.home_team
                away = game.away_team

                print(f"{away.full_name} @ {home.full_name}")
                print(f"  Score: {away.score} - {home.score}")
                print(f"  Status: {game.game_status}")
                print()

                # Get box score for completed games
                if game.game_status == "FINAL":
                    box = nfl.games.get_box_score(game_id=game.id)
                    print(f"  Total Yards - Home: {box.home_team_stats.total_yards}")
                    print()

        except GriddyError as e:
            print(f"Error: {e.message}")

if __name__ == "__main__":
    main()
```

## Next Steps

- [Async Patterns](../examples/python/async-patterns.md) - Advanced async usage
- [Error Handling](../guides/common-patterns/error-handling.md) - Comprehensive error handling
- [Data Models](../guides/data-models/games.md) - Understanding response data
