# Fetching Player Stats

This example demonstrates how to fetch and work with player statistics.

## Complete Example

```python
"""
Fetch and analyze player statistics using Griddy SDK.
"""

from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError

def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    try:
        # Fetch all stat categories
        passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)
        rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)
        receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)

        # Display top passers
        print("=== TOP 10 PASSERS ===")
        for player in passing.players[:10]:
            print(f"{player.player_name} ({player.team_abbreviation})")
            print(f"  {player.completions}/{player.attempts} "
                  f"({player.completion_percentage:.1f}%)")
            print(f"  {player.passing_yards} yds, {player.passing_touchdowns} TD, "
                  f"{player.interceptions} INT")
            print(f"  Rating: {player.passer_rating:.1f}")
            print()

        # Display top rushers
        print("=== TOP 10 RUSHERS ===")
        for player in rushing.players[:10]:
            print(f"{player.player_name} ({player.team_abbreviation})")
            print(f"  {player.rushing_yards} yds on {player.rushing_attempts} att")
            print(f"  {player.yards_per_attempt:.1f} YPC, {player.rushing_touchdowns} TD")
            print()

        # Display top receivers
        print("=== TOP 10 RECEIVERS ===")
        for player in receiving.players[:10]:
            print(f"{player.player_name} ({player.team_abbreviation})")
            print(f"  {player.receptions} rec, {player.receiving_yards} yds")
            print(f"  {player.receiving_touchdowns} TD, "
                  f"{player.yards_per_reception:.1f} YPR")
            print()

    except GriddyError as e:
        print(f"Error: {e.message}")

if __name__ == "__main__":
    main()
```

## Passing Statistics

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Get season passing stats
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)

# Access individual player stats
for player in passing.players:
    print(f"Player: {player.player_name}")
    print(f"  Team: {player.team_abbreviation}")
    print(f"  Completions: {player.completions}")
    print(f"  Attempts: {player.attempts}")
    print(f"  Completion %: {player.completion_percentage:.1f}%")
    print(f"  Passing Yards: {player.passing_yards}")
    print(f"  Touchdowns: {player.passing_touchdowns}")
    print(f"  Interceptions: {player.interceptions}")
    print(f"  Passer Rating: {player.passer_rating:.1f}")
    print(f"  Yards/Attempt: {player.yards_per_attempt:.1f}")

# Get weekly stats
week1_passing = nfl.stats.passing.get_passing_stats_by_week(season=2024, week=1)
```

## Rushing Statistics

```python
# Get season rushing stats
rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)

for player in rushing.players:
    print(f"Player: {player.player_name}")
    print(f"  Rushing Yards: {player.rushing_yards}")
    print(f"  Attempts: {player.rushing_attempts}")
    print(f"  Yards/Attempt: {player.yards_per_attempt:.1f}")
    print(f"  Touchdowns: {player.rushing_touchdowns}")
    print(f"  Longest Rush: {player.longest_rush}")
    print(f"  Fumbles: {player.fumbles}")
```

## Receiving Statistics

```python
# Get season receiving stats
receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)

for player in receiving.players:
    print(f"Player: {player.player_name}")
    print(f"  Receptions: {player.receptions}")
    print(f"  Targets: {player.targets}")
    print(f"  Receiving Yards: {player.receiving_yards}")
    print(f"  Yards/Reception: {player.yards_per_reception:.1f}")
    print(f"  Touchdowns: {player.receiving_touchdowns}")
    print(f"  Catch %: {player.catch_percentage:.1f}%")
```

## Defensive Statistics

```python
# Get defensive stats
defense = nfl.stats.defense.get_defensive_stats_by_season(season=2024)

for player in defense.players:
    print(f"Player: {player.player_name}")
    print(f"  Tackles: {player.tackles}")
    print(f"  Sacks: {player.sacks}")
    print(f"  Interceptions: {player.interceptions}")
    print(f"  Forced Fumbles: {player.forced_fumbles}")
    print(f"  Passes Defended: {player.passes_defended}")
```

## Next Gen Stats

```python
# Get NGS passing stats
ngs_passing = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG"
)

for player in ngs_passing:
    print(f"Player: {player.player_display_name}")
    print(f"  Avg Time to Throw: {player.avg_time_to_throw:.2f}s")
    print(f"  Aggressiveness: {player.aggressiveness:.1f}%")
    print(f"  Avg Air Yards: {player.avg_intended_air_yards:.1f}")
    print(f"  Completion % Above Expected: {player.completion_percentage_above_expected:.1f}%")

# Get NGS rushing stats
ngs_rushing = nfl.ngs.stats.get_rushing_stats(
    season=2024,
    season_type="REG"
)

for player in ngs_rushing:
    print(f"Player: {player.player_display_name}")
    print(f"  Efficiency: {player.efficiency:.1f}")
    print(f"  Yards Over Expected: {player.rush_yards_over_expected:.1f}")
```

## Filtering and Analysis

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Get passing stats
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)

# Filter by minimum attempts
qualified_passers = [
    p for p in passing.players
    if p.attempts >= 100
]

# Sort by passer rating
top_rated = sorted(
    qualified_passers,
    key=lambda p: p.passer_rating,
    reverse=True
)[:10]

print("Top 10 Passer Ratings (min 100 attempts)")
for i, player in enumerate(top_rated, 1):
    print(f"{i}. {player.player_name}: {player.passer_rating:.1f}")

# Find players on specific team
team_abbr = "KC"
chiefs_passers = [
    p for p in passing.players
    if p.team_abbreviation == team_abbr
]

# Calculate league averages
total_yards = sum(p.passing_yards for p in qualified_passers)
total_tds = sum(p.passing_touchdowns for p in qualified_passers)
avg_rating = sum(p.passer_rating for p in qualified_passers) / len(qualified_passers)

print(f"\nLeague Totals (qualified passers):")
print(f"  Total Yards: {total_yards:,}")
print(f"  Total TDs: {total_tds}")
print(f"  Avg Rating: {avg_rating:.1f}")
```

## Compare Players

```python
def compare_qbs(nfl, player_names: list, season: int = 2024):
    """Compare quarterback statistics."""
    passing = nfl.stats.passing.get_passing_stats_by_season(season=season)

    players = {
        p.player_name: p
        for p in passing.players
        if p.player_name in player_names
    }

    # Print comparison table
    print(f"{'Stat':<20}", end="")
    for name in player_names:
        print(f"{name:<15}", end="")
    print()

    print("-" * (20 + 15 * len(player_names)))

    stats_to_compare = [
        ("Comp %", "completion_percentage", ".1f"),
        ("Yards", "passing_yards", ",d"),
        ("TD", "passing_touchdowns", "d"),
        ("INT", "interceptions", "d"),
        ("Rating", "passer_rating", ".1f"),
        ("YPA", "yards_per_attempt", ".1f"),
    ]

    for stat_name, attr, fmt in stats_to_compare:
        print(f"{stat_name:<20}", end="")
        for name in player_names:
            if name in players:
                value = getattr(players[name], attr)
                print(f"{value:{fmt}:<15}", end="")
            else:
                print(f"{'N/A':<15}", end="")
        print()

# Usage
compare_qbs(nfl, ["Patrick Mahomes", "Josh Allen", "Lamar Jackson"])
```

## Export to DataFrame

```python
import pandas as pd
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Get stats
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)

# Convert to DataFrame
df = pd.DataFrame([
    {
        'name': p.player_name,
        'team': p.team_abbreviation,
        'completions': p.completions,
        'attempts': p.attempts,
        'yards': p.passing_yards,
        'touchdowns': p.passing_touchdowns,
        'interceptions': p.interceptions,
        'rating': p.passer_rating
    }
    for p in passing.players
])

# Analysis with pandas
print(df.describe())
print(df.nlargest(10, 'yards'))
```
