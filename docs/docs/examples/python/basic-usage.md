# Basic Usage

This example demonstrates fundamental SDK usage patterns.

## Complete Example

```python
"""
Basic Griddy SDK usage example.

This script demonstrates:
- Initializing the SDK
- Fetching game data
- Accessing team and game information
- Using context managers
"""

from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError

def main():
    # Initialize with auth token
    with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
        try:
            # Get week 1 games
            print("Fetching Week 1 games...")
            games = nfl.games.get_games(
                season=2024,
                season_type="REG",
                week=1
            )

            print(f"Found {len(games.games)} games\n")

            # Display each game
            for game in games.games:
                home = game.home_team
                away = game.away_team

                print(f"{away.full_name} @ {home.full_name}")
                print(f"  Status: {game.game_status}")

                if game.game_status in ["FINAL", "FINAL_OVERTIME"]:
                    print(f"  Score: {away.abbreviation} {away.score} - {home.score} {home.abbreviation}")

                print()

        except GriddyError as e:
            print(f"Error: {e.message}")
            if e.status_code:
                print(f"Status code: {e.status_code}")

if __name__ == "__main__":
    main()
```

## Breaking It Down

### Initialization

```python
from griddy.nfl import GriddyNFL

# Option 1: Direct initialization
nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

# Option 2: Context manager (recommended)
with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
    # Use nfl here
    pass  # Resources automatically cleaned up

# Option 3: Browser authentication (Python only)
nfl = GriddyNFL(
    login_email="user@example.com",
    login_password="password",
    headless_login=True
)
```

### Fetching Games

```python
# Regular season games
games = nfl.games.get_games(
    season=2024,
    season_type="REG",
    week=1
)

# Preseason games
preseason = nfl.games.get_games(
    season=2024,
    season_type="PRE",
    week=1
)

# Playoff games
playoffs = nfl.games.get_games(
    season=2024,
    season_type="POST",
    week=1
)
```

### Accessing Game Data

```python
for game in games.games:
    # Game identification
    print(f"Game ID: {game.id}")

    # Teams
    print(f"Home: {game.home_team.full_name} ({game.home_team.abbreviation})")
    print(f"Away: {game.away_team.full_name} ({game.away_team.abbreviation})")

    # Scores
    print(f"Home Score: {game.home_team.score}")
    print(f"Away Score: {game.away_team.score}")

    # Status
    print(f"Status: {game.game_status}")

    # Venue (if available)
    if game.venue:
        print(f"Venue: {game.venue.name}")
```

### Box Scores

```python
# Get detailed box score for a game
box_score = nfl.games.get_box_score(game_id=game.id)

# Access team statistics
print(f"Home total yards: {box_score.home_team_stats.total_yards}")
print(f"Away total yards: {box_score.away_team_stats.total_yards}")
```

### Play-by-Play

```python
# Get play-by-play data
pbp = nfl.games.get_play_by_play(
    game_id=game.id,
    include_penalties=True,
    include_formations=False
)

# Iterate through plays
for play in pbp.plays:
    print(f"Q{play.quarter}: {play.description}")
```

## Filtering Results

```python
# Filter games by status
completed = [g for g in games.games if g.game_status == "FINAL"]
in_progress = [g for g in games.games if g.game_status == "IN_PROGRESS"]
scheduled = [g for g in games.games if g.game_status == "SCHEDULED"]

# Filter games by team
team_abbr = "KC"
chiefs_games = [
    g for g in games.games
    if g.home_team.abbreviation == team_abbr or
       g.away_team.abbreviation == team_abbr
]

# Get specific matchup
matchup = next(
    (g for g in games.games
     if {g.home_team.abbreviation, g.away_team.abbreviation} == {"KC", "DET"}),
    None
)
```

## Working with Multiple Weeks

```python
def get_team_record(nfl, team_abbr: str, season: int) -> tuple:
    """Calculate team's win-loss record."""
    wins = losses = ties = 0

    for week in range(1, 19):
        games = nfl.games.get_games(
            season=season,
            season_type="REG",
            week=week
        )

        for game in games.games:
            if game.game_status not in ["FINAL", "FINAL_OVERTIME"]:
                continue

            is_home = game.home_team.abbreviation == team_abbr
            is_away = game.away_team.abbreviation == team_abbr

            if not (is_home or is_away):
                continue

            if is_home:
                team_score = game.home_team.score
                opp_score = game.away_team.score
            else:
                team_score = game.away_team.score
                opp_score = game.home_team.score

            if team_score > opp_score:
                wins += 1
            elif team_score < opp_score:
                losses += 1
            else:
                ties += 1

    return wins, losses, ties

# Usage
wins, losses, ties = get_team_record(nfl, "KC", 2024)
print(f"Chiefs record: {wins}-{losses}-{ties}")
```

## Output Formatting

```python
def format_game(game) -> str:
    """Format game for display."""
    home = game.home_team
    away = game.away_team

    if game.game_status in ["FINAL", "FINAL_OVERTIME"]:
        overtime = " (OT)" if game.game_status == "FINAL_OVERTIME" else ""
        return f"{away.abbreviation} {away.score} @ {home.abbreviation} {home.score}{overtime} - FINAL"
    elif game.game_status == "IN_PROGRESS":
        return f"{away.abbreviation} {away.score} @ {home.abbreviation} {home.score} - LIVE"
    else:
        return f"{away.abbreviation} @ {home.abbreviation} - {game.game_status}"

# Usage
for game in games.games:
    print(format_game(game))
```
