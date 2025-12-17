# Tutorial: Game Stats Dashboard

Build a simple dashboard displaying NFL game statistics.

## What You'll Build

A command-line dashboard that displays:

- Current week's game scores
- Team statistics for each game
- Top performers of the week

## Prerequisites

- Completed the [First API Call](first-api-call.md) tutorial
- Python 3.14+ with griddy installed

## Step 1: Project Setup

Create a new directory for your project:

```bash
mkdir nfl-dashboard
cd nfl-dashboard
```

Create `dashboard.py`:

```python
#!/usr/bin/env python3
"""NFL Game Stats Dashboard."""

import os
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError

def get_client():
    """Get authenticated NFL client."""
    token = os.environ.get("NFL_ACCESS_TOKEN")
    if not token:
        raise ValueError("Please set NFL_ACCESS_TOKEN environment variable")
    return GriddyNFL(nfl_auth={"accessToken": token})
```

## Step 2: Fetch Game Data

Add a function to fetch games for a specific week:

```python
def fetch_games(nfl, season: int, week: int):
    """Fetch games for a specific week."""
    games = nfl.games.get_games(
        season=season,
        season_type="REG",
        week=week
    )
    return games.games
```

## Step 3: Display Scoreboard

Create a formatted scoreboard display:

```python
def display_scoreboard(games):
    """Display game scoreboard."""
    print("\n" + "=" * 60)
    print(" NFL SCOREBOARD ".center(60, "="))
    print("=" * 60 + "\n")

    for game in games:
        home = game.home_team
        away = game.away_team
        status = game.game_status

        # Format team names and scores
        away_display = f"{away.abbreviation:>3}"
        home_display = f"{home.abbreviation:>3}"

        if status in ["FINAL", "FINAL_OVERTIME", "IN_PROGRESS"]:
            away_score = f"{away.score:>2}"
            home_score = f"{home.score:>2}"
            score_line = f"{away_display} {away_score}  @  {home_score} {home_display}"
        else:
            score_line = f"{away_display}      @       {home_display}"

        # Status indicator
        if status == "IN_PROGRESS":
            status_str = "LIVE"
        elif status == "FINAL_OVERTIME":
            status_str = "F/OT"
        elif status == "FINAL":
            status_str = "FINAL"
        else:
            status_str = status[:10]

        print(f"  {score_line}   [{status_str:^10}]")

    print()
```

## Step 4: Fetch Box Scores

Add functionality to get detailed game statistics:

```python
def fetch_box_score(nfl, game_id: str):
    """Fetch box score for a game."""
    try:
        return nfl.games.get_box_score(game_id=game_id)
    except GriddyError:
        return None

def display_game_details(nfl, game):
    """Display detailed stats for a single game."""
    print(f"\n{'=' * 60}")
    print(f" {game.away_team.full_name} @ {game.home_team.full_name} ".center(60, "="))
    print("=" * 60)

    box = fetch_box_score(nfl, game.id)
    if not box:
        print("  Box score not available")
        return

    # Display team stats comparison
    print("\n  TEAM STATS")
    print("-" * 40)

    stats = [
        ("Total Yards", "total_yards"),
        ("Passing Yards", "passing_yards"),
        ("Rushing Yards", "rushing_yards"),
        ("Turnovers", "turnovers"),
    ]

    away_abbr = game.away_team.abbreviation
    home_abbr = game.home_team.abbreviation

    print(f"  {'':20} {away_abbr:>8} {home_abbr:>8}")
    print("  " + "-" * 36)

    for label, attr in stats:
        away_val = getattr(box.away_team_stats, attr, "N/A")
        home_val = getattr(box.home_team_stats, attr, "N/A")
        print(f"  {label:20} {str(away_val):>8} {str(home_val):>8}")
```

## Step 5: Top Performers

Add weekly top performers:

```python
def display_top_performers(nfl, season: int, week: int):
    """Display top performers for the week."""
    print("\n" + "=" * 60)
    print(" TOP PERFORMERS ".center(60, "="))
    print("=" * 60)

    # Get passing stats
    try:
        passing = nfl.stats.passing.get_passing_stats_by_week(
            season=season, week=week
        )

        print("\n  TOP PASSERS")
        print("  " + "-" * 40)
        for player in passing.players[:3]:
            print(f"  {player.player_name:20} {player.passing_yards:>4} YDS, "
                  f"{player.passing_touchdowns} TD")
    except GriddyError:
        print("  Passing stats not available")

    # Get rushing stats
    try:
        rushing = nfl.stats.rushing.get_rushing_stats_by_week(
            season=season, week=week
        )

        print("\n  TOP RUSHERS")
        print("  " + "-" * 40)
        for player in rushing.players[:3]:
            print(f"  {player.player_name:20} {player.rushing_yards:>4} YDS, "
                  f"{player.rushing_touchdowns} TD")
    except GriddyError:
        print("  Rushing stats not available")

    # Get receiving stats
    try:
        receiving = nfl.stats.receiving.get_receiving_stats_by_week(
            season=season, week=week
        )

        print("\n  TOP RECEIVERS")
        print("  " + "-" * 40)
        for player in receiving.players[:3]:
            print(f"  {player.player_name:20} {player.receiving_yards:>4} YDS, "
                  f"{player.receptions} REC")
    except GriddyError:
        print("  Receiving stats not available")

    print()
```

## Step 6: Main Dashboard

Combine everything into the main dashboard:

```python
def main():
    """Main dashboard function."""
    import argparse

    parser = argparse.ArgumentParser(description="NFL Game Stats Dashboard")
    parser.add_argument("--season", type=int, default=2024, help="Season year")
    parser.add_argument("--week", type=int, default=1, help="Week number")
    parser.add_argument("--details", action="store_true", help="Show game details")
    args = parser.parse_args()

    try:
        nfl = get_client()

        # Fetch and display games
        games = fetch_games(nfl, args.season, args.week)

        print(f"\n  Season {args.season} - Week {args.week}")
        display_scoreboard(games)

        # Show details for completed games
        if args.details:
            completed = [g for g in games
                        if g.game_status in ["FINAL", "FINAL_OVERTIME"]]
            for game in completed[:3]:  # Limit to 3 games
                display_game_details(nfl, game)

        # Show top performers
        display_top_performers(nfl, args.season, args.week)

    except ValueError as e:
        print(f"Configuration error: {e}")
    except GriddyError as e:
        print(f"API error: {e.message}")

if __name__ == "__main__":
    main()
```

## Step 7: Run the Dashboard

```bash
# Basic usage
python dashboard.py --season 2024 --week 1

# With game details
python dashboard.py --season 2024 --week 1 --details
```

## Sample Output

```
  Season 2024 - Week 1

============================================================
================= NFL SCOREBOARD ==================
============================================================

  BAL 27  @  20  KC   [  FINAL   ]
  GB  34  @  29 PHI   [  FINAL   ]
  ARI 28  @  34 BUF   [  FINAL   ]
  ...

============================================================
=============== TOP PERFORMERS ================
============================================================

  TOP PASSERS
  ----------------------------------------
  Patrick Mahomes       241 YDS, 2 TD
  Josh Allen            312 YDS, 3 TD
  Jalen Hurts           278 YDS, 2 TD

  TOP RUSHERS
  ----------------------------------------
  Saquon Barkley        109 YDS, 1 TD
  Derrick Henry          98 YDS, 2 TD
  ...
```

## Next Steps

- Add automatic refresh for live games
- Create a web interface with Flask
- Add historical comparison features

## Complete Code

See the [full source code](https://github.com/jkgriebel93/griddy-sdk-python/examples/dashboard.py) for the complete implementation.
