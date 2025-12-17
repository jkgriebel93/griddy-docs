# Pagination

This guide covers working with paginated responses from the Griddy SDK.

## Overview

While most NFL API endpoints don't use traditional pagination, you'll encounter scenarios where you need to iterate through large datasets:

- Fetching all weeks in a season
- Getting statistics for all players
- Retrieving historical data across multiple seasons

## Iterating Through Weeks

### Python

```python
from griddy.nfl import GriddyNFL
from typing import List

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

def get_all_regular_season_games(season: int) -> List:
    """Fetch all regular season games."""
    all_games = []

    for week in range(1, 19):  # Regular season has 18 weeks
        games = nfl.games.get_games(
            season=season,
            season_type="REG",
            week=week
        )
        all_games.extend(games.games)

    return all_games

games_2024 = get_all_regular_season_games(2024)
print(f"Total games: {len(games_2024)}")
```

### TypeScript

```typescript
import { GriddyNFL } from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

async function getAllRegularSeasonGames(season: number) {
  const allGames = [];

  for (let week = 1; week <= 18; week++) {
    const games = await nfl.games.getGames(season, 'REG', week);
    allGames.push(...(games.games ?? []));
  }

  return allGames;
}

const games2024 = await getAllRegularSeasonGames(2024);
console.log(`Total games: ${games2024.length}`);
```

## Generator Pattern

Use generators for memory-efficient iteration:

### Python

```python
from typing import Generator, Any

def iterate_season_games(
    nfl,
    season: int,
    season_type: str = "REG"
) -> Generator:
    """Yield games week by week."""
    max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]

    for week in range(1, max_weeks + 1):
        games = nfl.games.get_games(
            season=season,
            season_type=season_type,
            week=week
        )

        for game in games.games:
            yield game

# Usage - processes one game at a time
for game in iterate_season_games(nfl, 2024, "REG"):
    print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")
```

### Async Generator

```python
async def iterate_season_games_async(
    nfl,
    season: int,
    season_type: str = "REG"
):
    """Async generator for season games."""
    max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]

    for week in range(1, max_weeks + 1):
        games = await nfl.games.get_games_async(
            season=season,
            season_type=season_type,
            week=week
        )

        for game in games.games:
            yield game

# Usage
async for game in iterate_season_games_async(nfl, 2024, "REG"):
    print(game.id)
```

## Concurrent Fetching

Fetch multiple pages concurrently for better performance:

### Python

```python
import asyncio
from typing import List

async def get_all_games_concurrent(nfl, season: int) -> List:
    """Fetch all weeks concurrently."""

    async def get_week(week: int):
        return await nfl.games.get_games_async(
            season=season,
            season_type="REG",
            week=week
        )

    # Fetch all weeks concurrently
    tasks = [get_week(week) for week in range(1, 19)]
    results = await asyncio.gather(*tasks)

    # Flatten results
    all_games = []
    for result in results:
        all_games.extend(result.games)

    return all_games

# Usage
games = asyncio.run(get_all_games_concurrent(nfl, 2024))
```

### TypeScript

```typescript
async function getAllGamesConcurrent(nfl: GriddyNFL, season: number) {
  const weeks = Array.from({ length: 18 }, (_, i) => i + 1);

  const results = await Promise.all(
    weeks.map(week => nfl.games.getGames(season, 'REG', week))
  );

  return results.flatMap(r => r.games ?? []);
}
```

## Rate-Limited Pagination

Combine pagination with rate limiting:

```python
import asyncio

class PaginatedFetcher:
    def __init__(self, nfl, requests_per_minute: int = 60):
        self.nfl = nfl
        self.delay = 60 / requests_per_minute

    async def get_all_weeks(self, season: int, season_type: str = "REG"):
        """Fetch all weeks with rate limiting."""
        max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]
        all_games = []

        for week in range(1, max_weeks + 1):
            games = await self.nfl.games.get_games_async(
                season=season,
                season_type=season_type,
                week=week
            )
            all_games.extend(games.games)

            # Rate limit
            await asyncio.sleep(self.delay)

        return all_games

# Usage
fetcher = PaginatedFetcher(nfl, requests_per_minute=60)
games = asyncio.run(fetcher.get_all_weeks(2024))
```

## Multiple Seasons

Iterate through multiple seasons:

```python
def get_historical_data(nfl, start_season: int, end_season: int):
    """Get games across multiple seasons."""
    for season in range(start_season, end_season + 1):
        print(f"Fetching {season} season...")

        for season_type in ["PRE", "REG", "POST"]:
            max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]

            for week in range(1, max_weeks + 1):
                try:
                    games = nfl.games.get_games(
                        season=season,
                        season_type=season_type,
                        week=week
                    )

                    for game in games.games:
                        yield {
                            'season': season,
                            'season_type': season_type,
                            'week': week,
                            'game': game
                        }

                except Exception as e:
                    print(f"Error fetching {season} {season_type} week {week}: {e}")

# Usage
for data in get_historical_data(nfl, 2020, 2024):
    game = data['game']
    print(f"{data['season']} Week {data['week']}: {game.id}")
```

## Pagination State Management

Track pagination state for resumable operations:

```python
import json
from dataclasses import dataclass, asdict
from pathlib import Path

@dataclass
class PaginationState:
    season: int
    season_type: str
    last_completed_week: int
    total_games_fetched: int

    def save(self, path: str = "pagination_state.json"):
        with open(path, 'w') as f:
            json.dump(asdict(self), f)

    @classmethod
    def load(cls, path: str = "pagination_state.json"):
        if Path(path).exists():
            with open(path) as f:
                return cls(**json.load(f))
        return None

class ResumableFetcher:
    def __init__(self, nfl, state_path: str = "pagination_state.json"):
        self.nfl = nfl
        self.state_path = state_path

    def fetch_season(self, season: int, season_type: str = "REG"):
        """Fetch season data with resume capability."""

        # Try to resume from saved state
        state = PaginationState.load(self.state_path)

        if state and state.season == season and state.season_type == season_type:
            start_week = state.last_completed_week + 1
            print(f"Resuming from week {start_week}")
        else:
            state = PaginationState(
                season=season,
                season_type=season_type,
                last_completed_week=0,
                total_games_fetched=0
            )
            start_week = 1

        max_weeks = {"PRE": 4, "REG": 18, "POST": 4}[season_type]
        all_games = []

        for week in range(start_week, max_weeks + 1):
            try:
                games = self.nfl.games.get_games(
                    season=season,
                    season_type=season_type,
                    week=week
                )

                all_games.extend(games.games)

                # Update and save state
                state.last_completed_week = week
                state.total_games_fetched += len(games.games)
                state.save(self.state_path)

            except Exception as e:
                print(f"Error at week {week}: {e}")
                print("Progress saved. Resume later.")
                raise

        # Clean up state file on completion
        Path(self.state_path).unlink(missing_ok=True)

        return all_games
```

## Best Practices

1. **Use generators**: For memory efficiency with large datasets
2. **Implement rate limiting**: Respect API limits during pagination
3. **Fetch concurrently**: Use async/await for better performance
4. **Track progress**: Save state for resumable long-running operations
5. **Handle errors per page**: Don't let one failure stop the entire fetch
6. **Batch appropriately**: Balance between too many requests and memory usage
