# Async Patterns

This example demonstrates asynchronous programming patterns with the Griddy SDK.

## Basic Async Usage

```python
import asyncio
from griddy.nfl import GriddyNFL

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    # Use async method (note the _async suffix)
    games = await nfl.games.get_games_async(
        season=2024,
        season_type="REG",
        week=1
    )

    for game in games.games:
        print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")

asyncio.run(main())
```

## Concurrent Requests

Fetch multiple endpoints simultaneously:

```python
import asyncio
from griddy.nfl import GriddyNFL

async def fetch_all_data(nfl):
    """Fetch games, passing stats, and rushing stats concurrently."""

    # Create tasks for concurrent execution
    games_task = nfl.games.get_games_async(
        season=2024,
        season_type="REG",
        week=1
    )

    passing_task = nfl.stats.passing.get_passing_stats_by_season_async(
        season=2024
    )

    rushing_task = nfl.stats.rushing.get_rushing_stats_by_season_async(
        season=2024
    )

    # Execute all tasks concurrently
    games, passing, rushing = await asyncio.gather(
        games_task,
        passing_task,
        rushing_task
    )

    return {
        'games': games,
        'passing': passing,
        'rushing': rushing
    }

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})
    data = await fetch_all_data(nfl)

    print(f"Games: {len(data['games'].games)}")
    print(f"Passers: {len(data['passing'].players)}")
    print(f"Rushers: {len(data['rushing'].players)}")

asyncio.run(main())
```

## Fetching Multiple Weeks

```python
import asyncio
from griddy.nfl import GriddyNFL

async def get_all_season_games(nfl, season: int, season_type: str = "REG"):
    """Fetch all weeks of a season concurrently."""
    max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]

    async def get_week(week: int):
        return await nfl.games.get_games_async(
            season=season,
            season_type=season_type,
            week=week
        )

    # Create tasks for all weeks
    tasks = [get_week(week) for week in range(1, max_weeks + 1)]

    # Execute all concurrently
    results = await asyncio.gather(*tasks)

    # Flatten to single list
    all_games = []
    for week_games in results:
        all_games.extend(week_games.games)

    return all_games

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    games = await get_all_season_games(nfl, 2024, "REG")
    print(f"Total regular season games: {len(games)}")

asyncio.run(main())
```

## Rate-Limited Concurrent Requests

```python
import asyncio
from griddy.nfl import GriddyNFL

class AsyncRateLimiter:
    """Semaphore-based rate limiter for async requests."""

    def __init__(self, max_concurrent: int = 5):
        self.semaphore = asyncio.Semaphore(max_concurrent)

    async def acquire(self):
        await self.semaphore.acquire()

    def release(self):
        self.semaphore.release()

async def rate_limited_fetch(nfl, limiter, season, season_type, week):
    """Fetch with rate limiting."""
    await limiter.acquire()
    try:
        return await nfl.games.get_games_async(
            season=season,
            season_type=season_type,
            week=week
        )
    finally:
        limiter.release()
        await asyncio.sleep(0.1)  # Small delay between requests

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})
    limiter = AsyncRateLimiter(max_concurrent=5)

    tasks = [
        rate_limited_fetch(nfl, limiter, 2024, "REG", week)
        for week in range(1, 19)
    ]

    results = await asyncio.gather(*tasks)

    total_games = sum(len(r.games) for r in results)
    print(f"Total games: {total_games}")

asyncio.run(main())
```

## Async Generator

Stream results as they become available:

```python
import asyncio
from griddy.nfl import GriddyNFL
from typing import AsyncGenerator, Any

async def stream_games(
    nfl,
    season: int,
    season_type: str = "REG"
) -> AsyncGenerator[Any, None]:
    """Async generator that yields games as they're fetched."""
    max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]

    for week in range(1, max_weeks + 1):
        games = await nfl.games.get_games_async(
            season=season,
            season_type=season_type,
            week=week
        )

        for game in games.games:
            yield {
                'week': week,
                'game': game
            }

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    async for data in stream_games(nfl, 2024, "REG"):
        game = data['game']
        print(f"Week {data['week']}: {game.away_team.abbreviation} @ {game.home_team.abbreviation}")

asyncio.run(main())
```

## Async Context Manager

```python
import asyncio
from griddy.nfl import GriddyNFL

async def main():
    # Async context manager for automatic cleanup
    async with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
        games = await nfl.games.get_games_async(
            season=2024,
            season_type="REG",
            week=1
        )

        for game in games.games:
            print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")

    # Resources automatically cleaned up

asyncio.run(main())
```

## Error Handling in Async Code

```python
import asyncio
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError, RateLimitError

async def fetch_with_retry(nfl, season, season_type, week, max_retries=3):
    """Async fetch with exponential backoff retry."""
    for attempt in range(max_retries):
        try:
            return await nfl.games.get_games_async(
                season=season,
                season_type=season_type,
                week=week
            )

        except RateLimitError as e:
            if attempt < max_retries - 1:
                wait = e.retry_after or (2 ** attempt)
                print(f"Rate limited. Waiting {wait}s...")
                await asyncio.sleep(wait)
            else:
                raise

        except GriddyError as e:
            if e.status_code and e.status_code >= 500:
                if attempt < max_retries - 1:
                    wait = 2 ** attempt
                    print(f"Server error. Waiting {wait}s...")
                    await asyncio.sleep(wait)
                else:
                    raise
            else:
                raise

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    try:
        games = await fetch_with_retry(nfl, 2024, "REG", 1)
        print(f"Fetched {len(games.games)} games")
    except GriddyError as e:
        print(f"Failed after retries: {e.message}")

asyncio.run(main())
```

## Processing Results Asynchronously

```python
import asyncio
from griddy.nfl import GriddyNFL

async def process_game(game):
    """Async processing of a single game."""
    # Simulate async processing (e.g., database insert)
    await asyncio.sleep(0.01)
    return {
        'id': game.id,
        'matchup': f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}",
        'status': game.game_status
    }

async def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    games = await nfl.games.get_games_async(
        season=2024,
        season_type="REG",
        week=1
    )

    # Process all games concurrently
    tasks = [process_game(game) for game in games.games]
    processed = await asyncio.gather(*tasks)

    for item in processed:
        print(item)

asyncio.run(main())
```

## Integration with Web Frameworks

### FastAPI Example

```python
from fastapi import FastAPI
from griddy.nfl import GriddyNFL

app = FastAPI()
nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

@app.get("/games/{season}/{season_type}/{week}")
async def get_games(season: int, season_type: str, week: int):
    games = await nfl.games.get_games_async(
        season=season,
        season_type=season_type,
        week=week
    )

    return {
        "count": len(games.games),
        "games": [
            {
                "id": g.id,
                "home": g.home_team.abbreviation,
                "away": g.away_team.abbreviation,
                "status": g.game_status
            }
            for g in games.games
        ]
    }
```

### aiohttp Example

```python
import asyncio
from aiohttp import web
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

async def get_games(request):
    season = int(request.match_info['season'])
    week = int(request.match_info['week'])

    games = await nfl.games.get_games_async(
        season=season,
        season_type="REG",
        week=week
    )

    return web.json_response({
        "count": len(games.games),
        "games": [g.id for g in games.games]
    })

app = web.Application()
app.router.add_get('/games/{season}/{week}', get_games)

if __name__ == '__main__':
    web.run_app(app)
```
