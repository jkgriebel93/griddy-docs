# Tutorial: Player Comparison

Build a tool to compare NFL player statistics side-by-side.

## What You'll Build

A player comparison tool that:

- Fetches stats for multiple players
- Normalizes data for comparison
- Creates formatted comparison tables
- Identifies statistical advantages

## Prerequisites

- Completed the [First API Call](first-api-call.md) tutorial
- Python 3.14+ with griddy installed

## Step 1: Project Setup

```bash
mkdir player-compare
cd player-compare
touch compare.py
```

## Step 2: Create the Comparison Class

```python
#!/usr/bin/env python3
"""NFL Player Comparison Tool."""

import os
from dataclasses import dataclass
from typing import Dict, List, Optional, Any
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError

@dataclass
class PlayerStats:
    """Container for player statistics."""
    name: str
    team: str
    position: str
    stats: Dict[str, Any]

class PlayerComparison:
    """Compare NFL player statistics."""

    def __init__(self, nfl: GriddyNFL):
        self.nfl = nfl

    def find_player_stats(
        self,
        player_name: str,
        season: int,
        stat_type: str = "passing"
    ) -> Optional[PlayerStats]:
        """Find stats for a specific player."""

        # Get stats based on type
        if stat_type == "passing":
            data = self.nfl.stats.passing.get_passing_stats_by_season(season=season)
            players = data.players
        elif stat_type == "rushing":
            data = self.nfl.stats.rushing.get_rushing_stats_by_season(season=season)
            players = data.players
        elif stat_type == "receiving":
            data = self.nfl.stats.receiving.get_receiving_stats_by_season(season=season)
            players = data.players
        else:
            return None

        # Find the player
        for player in players:
            if player.player_name.lower() == player_name.lower():
                return PlayerStats(
                    name=player.player_name,
                    team=player.team_abbreviation,
                    position=stat_type.upper()[:2],
                    stats=self._extract_stats(player, stat_type)
                )

        return None

    def _extract_stats(self, player, stat_type: str) -> Dict[str, Any]:
        """Extract relevant stats based on position."""
        if stat_type == "passing":
            return {
                "Games": getattr(player, 'games', 0),
                "Completions": getattr(player, 'completions', 0),
                "Attempts": getattr(player, 'attempts', 0),
                "Comp %": getattr(player, 'completion_percentage', 0),
                "Yards": getattr(player, 'passing_yards', 0),
                "TD": getattr(player, 'passing_touchdowns', 0),
                "INT": getattr(player, 'interceptions', 0),
                "Rating": getattr(player, 'passer_rating', 0),
                "YPA": getattr(player, 'yards_per_attempt', 0),
            }
        elif stat_type == "rushing":
            return {
                "Games": getattr(player, 'games', 0),
                "Attempts": getattr(player, 'rushing_attempts', 0),
                "Yards": getattr(player, 'rushing_yards', 0),
                "TD": getattr(player, 'rushing_touchdowns', 0),
                "YPC": getattr(player, 'yards_per_attempt', 0),
                "Long": getattr(player, 'longest_rush', 0),
                "Fumbles": getattr(player, 'fumbles', 0),
            }
        elif stat_type == "receiving":
            return {
                "Games": getattr(player, 'games', 0),
                "Targets": getattr(player, 'targets', 0),
                "Receptions": getattr(player, 'receptions', 0),
                "Yards": getattr(player, 'receiving_yards', 0),
                "TD": getattr(player, 'receiving_touchdowns', 0),
                "YPR": getattr(player, 'yards_per_reception', 0),
                "Long": getattr(player, 'longest_reception', 0),
            }
        return {}

    def compare(
        self,
        player_names: List[str],
        season: int,
        stat_type: str = "passing"
    ) -> List[PlayerStats]:
        """Compare multiple players."""
        results = []
        for name in player_names:
            stats = self.find_player_stats(name, season, stat_type)
            if stats:
                results.append(stats)
            else:
                print(f"Warning: Could not find stats for {name}")
        return results
```

## Step 3: Create Display Functions

```python
def display_comparison(players: List[PlayerStats]):
    """Display comparison table."""
    if not players:
        print("No players to compare")
        return

    # Get all stat keys
    all_stats = set()
    for player in players:
        all_stats.update(player.stats.keys())
    all_stats = sorted(all_stats)

    # Header
    print("\n" + "=" * 70)
    print(" PLAYER COMPARISON ".center(70, "="))
    print("=" * 70)

    # Player names header
    header = f"{'Stat':15}"
    for player in players:
        header += f"{player.name[:15]:>18}"
    print(header)
    print("-" * 70)

    # Stats rows
    for stat in all_stats:
        row = f"{stat:15}"
        values = []

        for player in players:
            val = player.stats.get(stat, "N/A")
            if isinstance(val, float):
                row += f"{val:>18.1f}"
            else:
                row += f"{val:>18}"
            values.append(val if val != "N/A" else 0)

        # Highlight winner (higher is better for most stats)
        if len(values) > 1 and all(isinstance(v, (int, float)) for v in values):
            max_val = max(values)
            # For negative stats (INT, Fumbles), lower is better
            if stat in ["INT", "Fumbles"]:
                max_val = min(values)

        print(row)

    print("=" * 70 + "\n")

def display_advantage_summary(players: List[PlayerStats]):
    """Show which player has advantage in each category."""
    if len(players) != 2:
        return

    p1, p2 = players

    print("ADVANTAGE SUMMARY")
    print("-" * 40)

    p1_advantages = []
    p2_advantages = []

    # Stats where higher is better
    higher_better = ["Yards", "TD", "Rating", "Comp %", "YPA", "YPC", "YPR",
                     "Receptions", "Long", "Completions", "Attempts", "Targets"]

    # Stats where lower is better
    lower_better = ["INT", "Fumbles"]

    for stat in p1.stats:
        v1 = p1.stats.get(stat, 0)
        v2 = p2.stats.get(stat, 0)

        if not isinstance(v1, (int, float)) or not isinstance(v2, (int, float)):
            continue

        if stat in higher_better:
            if v1 > v2:
                p1_advantages.append(stat)
            elif v2 > v1:
                p2_advantages.append(stat)
        elif stat in lower_better:
            if v1 < v2:
                p1_advantages.append(stat)
            elif v2 < v1:
                p2_advantages.append(stat)

    print(f"{p1.name}: {', '.join(p1_advantages) or 'None'}")
    print(f"{p2.name}: {', '.join(p2_advantages) or 'None'}")
    print()
```

## Step 4: Add Chart Visualization (Optional)

```python
def display_bar_chart(players: List[PlayerStats], stat: str, width: int = 40):
    """Display a simple text-based bar chart for a stat."""
    values = [(p.name, p.stats.get(stat, 0)) for p in players]
    max_val = max(v for _, v in values) if values else 1

    print(f"\n{stat}:")
    for name, val in values:
        bar_len = int((val / max_val) * width) if max_val > 0 else 0
        bar = "█" * bar_len
        print(f"  {name:15} {bar} {val}")
```

## Step 5: Main Application

```python
def main():
    import argparse

    parser = argparse.ArgumentParser(description="NFL Player Comparison")
    parser.add_argument("players", nargs="+", help="Player names to compare")
    parser.add_argument("--season", type=int, default=2024)
    parser.add_argument("--type", choices=["passing", "rushing", "receiving"],
                       default="passing", help="Stat type to compare")
    parser.add_argument("--chart", help="Stat to show as bar chart")
    args = parser.parse_args()

    # Get token
    token = os.environ.get("NFL_ACCESS_TOKEN")
    if not token:
        print("Please set NFL_ACCESS_TOKEN environment variable")
        return

    try:
        nfl = GriddyNFL(nfl_auth={"accessToken": token})
        comparison = PlayerComparison(nfl)

        print(f"\nComparing {args.type} stats for {args.season} season...")

        players = comparison.compare(args.players, args.season, args.type)

        if players:
            display_comparison(players)

            if len(players) == 2:
                display_advantage_summary(players)

            if args.chart and players:
                display_bar_chart(players, args.chart)

    except GriddyError as e:
        print(f"API Error: {e.message}")

if __name__ == "__main__":
    main()
```

## Step 6: Run Comparisons

```bash
# Compare two quarterbacks
python compare.py "Patrick Mahomes" "Josh Allen" --type passing

# Compare running backs
python compare.py "Derrick Henry" "Saquon Barkley" --type rushing

# Compare with chart
python compare.py "Patrick Mahomes" "Josh Allen" --chart Yards

# Three-way comparison
python compare.py "Patrick Mahomes" "Josh Allen" "Lamar Jackson"
```

## Sample Output

```
Comparing passing stats for 2024 season...

======================================================================
====================== PLAYER COMPARISON ======================
======================================================================
Stat            Patrick Mahomes        Josh Allen
----------------------------------------------------------------------
Attempts                   612             587
Comp %                    66.2            65.8
Completions                405             386
Games                       17              17
INT                         11              10
Rating                    98.4           101.2
TD                          26              29
YPA                        8.2             8.5
Yards                     5027            4990
======================================================================

ADVANTAGE SUMMARY
----------------------------------------
Patrick Mahomes: Yards, Comp %, Completions
Josh Allen: TD, Rating, YPA, INT
```

## Enhancements

### Per-Game Stats

```python
def normalize_to_per_game(stats: Dict[str, Any], games: int) -> Dict[str, Any]:
    """Convert counting stats to per-game averages."""
    counting_stats = ["Yards", "TD", "Attempts", "Completions", "Receptions", "Targets"]
    normalized = {}

    for stat, val in stats.items():
        if stat in counting_stats and isinstance(val, (int, float)) and games > 0:
            normalized[f"{stat}/G"] = round(val / games, 1)
        else:
            normalized[stat] = val

    return normalized
```

### Export to CSV

```python
def export_to_csv(players: List[PlayerStats], filename: str):
    """Export comparison to CSV."""
    import csv

    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)

        # Header
        header = ["Stat"] + [p.name for p in players]
        writer.writerow(header)

        # Stats
        all_stats = set()
        for p in players:
            all_stats.update(p.stats.keys())

        for stat in sorted(all_stats):
            row = [stat] + [p.stats.get(stat, "") for p in players]
            writer.writerow(row)

    print(f"Exported to {filename}")
```

## Next Steps

- Add historical season comparisons
- Include Next Gen Stats metrics
- Create web interface with interactive charts
