# Schedules Data Model

This guide covers the schedule data structures returned by the Griddy SDK.

## Overview

The SDK provides access to NFL schedules through multiple endpoints:

- **Games endpoint**: Get games by season, type, and week
- **NGS League endpoint**: Get schedule information from Next Gen Stats
- **Weeks endpoint**: Get information about season weeks

## Getting Schedules

### By Week

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Get all games for a specific week
games = nfl.games.get_games(
    season=2024,
    season_type="REG",
    week=1
)

for game in games.games:
    print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")
    print(f"  Date: {game.game_time}")
    print(f"  Venue: {game.venue.name}")
```

### Full Season Schedule

```python
# Get all regular season games
all_games = []
for week in range(1, 19):  # Regular season is 18 weeks
    week_games = nfl.games.get_games(
        season=2024,
        season_type="REG",
        week=week
    )
    all_games.extend(week_games.games)

print(f"Total regular season games: {len(all_games)}")
```

### NGS Schedule

```python
# Get schedule from Next Gen Stats
schedule = nfl.ngs.league.get_schedule(season=2024)

for week in schedule.weeks:
    print(f"Week {week.week_number}:")
    for game in week.games:
        print(f"  {game.away_team} @ {game.home_team}")
```

## Season Structure

### Season Types

| Type | Description | Weeks |
|------|-------------|-------|
| `PRE` | Preseason | 1-4 |
| `REG` | Regular Season | 1-18 |
| `POST` | Postseason | 1-4 |

### Regular Season Weeks

The NFL regular season has 18 weeks:

```python
# Iterate through regular season
for week in range(1, 19):
    games = nfl.games.get_games(
        season=2024,
        season_type="REG",
        week=week
    )
    print(f"Week {week}: {len(games.games)} games")
```

### Bye Weeks

Teams have a bye week during the regular season:

```python
def get_team_schedule(nfl, team_abbr: str, season: int):
    """Get schedule for a specific team."""
    schedule = []

    for week in range(1, 19):
        games = nfl.games.get_games(
            season=season,
            season_type="REG",
            week=week
        )

        team_game = None
        for game in games.games:
            if (game.home_team.abbreviation == team_abbr or
                game.away_team.abbreviation == team_abbr):
                team_game = game
                break

        if team_game:
            is_home = team_game.home_team.abbreviation == team_abbr
            opponent = team_game.away_team if is_home else team_game.home_team
            schedule.append({
                "week": week,
                "opponent": opponent.abbreviation,
                "home": is_home,
                "game": team_game
            })
        else:
            schedule.append({
                "week": week,
                "bye": True
            })

    return schedule

# Get Chiefs schedule
kc_schedule = get_team_schedule(nfl, "KC", 2024)

for week_info in kc_schedule:
    if week_info.get("bye"):
        print(f"Week {week_info['week']}: BYE")
    else:
        prefix = "vs" if week_info["home"] else "@"
        print(f"Week {week_info['week']}: {prefix} {week_info['opponent']}")
```

### Postseason Structure

| Week | Round |
|------|-------|
| 1 | Wild Card |
| 2 | Divisional |
| 3 | Conference Championships |
| 4 | Super Bowl |

```python
# Get playoff games
wild_card = nfl.games.get_games(season=2024, season_type="POST", week=1)
divisional = nfl.games.get_games(season=2024, season_type="POST", week=2)
championship = nfl.games.get_games(season=2024, season_type="POST", week=3)
super_bowl = nfl.games.get_games(season=2024, season_type="POST", week=4)
```

## Game Timing

### Date and Time

```python
from datetime import datetime

games = nfl.games.get_games(season=2024, season_type="REG", week=1)

for game in games.games:
    # Game time is typically in ISO format
    print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")
    print(f"  Start: {game.game_time}")
    print(f"  Day: {game.game_day}")
```

### Time Slots

Common NFL game time slots:

| Day | Time (ET) | Description |
|-----|-----------|-------------|
| Sunday | 1:00 PM | Early games |
| Sunday | 4:05 PM | Late games (CBS) |
| Sunday | 4:25 PM | Late games (FOX) |
| Sunday | 8:20 PM | Sunday Night Football |
| Monday | 8:15 PM | Monday Night Football |
| Thursday | 8:20 PM | Thursday Night Football |

### Filtering by Day

```python
def get_games_by_day(games, day: str):
    """Filter games by day of week."""
    return [g for g in games.games if g.game_day == day]

week1 = nfl.games.get_games(season=2024, season_type="REG", week=1)

sunday_games = get_games_by_day(week1, "Sunday")
monday_game = get_games_by_day(week1, "Monday")
thursday_game = get_games_by_day(week1, "Thursday")

print(f"Sunday: {len(sunday_games)} games")
print(f"Monday: {len(monday_game)} games")
print(f"Thursday: {len(thursday_game)} games")
```

## Venue Information

Games include venue details:

```python
for game in games.games:
    venue = game.venue
    print(f"Game at: {venue.name}")
    print(f"  Location: {venue.city}, {venue.state}")
    print(f"  Surface: {venue.surface_type}")
    print(f"  Roof: {venue.roof_type}")
```

## Week Information

Get information about specific weeks:

```python
# Get week details
weeks = nfl.weeks.get_weeks(season=2024, season_type="REG")

for week in weeks:
    print(f"Week {week.week_number}")
    print(f"  Start: {week.start_date}")
    print(f"  End: {week.end_date}")
```

## International Games

NFL games played outside the US:

```python
# Check for international games
for week in range(1, 19):
    games = nfl.games.get_games(season=2024, season_type="REG", week=week)

    for game in games.games:
        if game.venue.country != "USA":
            print(f"Week {week}: {game.away_team.abbreviation} @ {game.home_team.abbreviation}")
            print(f"  Location: {game.venue.name}, {game.venue.city}")
```
