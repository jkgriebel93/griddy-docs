# Fantasy Integration

This example demonstrates how to use NFL data for fantasy football applications.

## Fantasy Scoring Calculator

```python
"""
Fantasy football scoring calculator using Griddy SDK.
"""

from griddy.nfl import GriddyNFL
from dataclasses import dataclass
from typing import Dict, List, Optional

@dataclass
class FantasyScoring:
    """Standard fantasy scoring rules."""
    passing_yard: float = 0.04      # 1 point per 25 yards
    passing_td: float = 4.0
    interception: float = -2.0
    rushing_yard: float = 0.1       # 1 point per 10 yards
    rushing_td: float = 6.0
    reception: float = 1.0          # PPR
    receiving_yard: float = 0.1     # 1 point per 10 yards
    receiving_td: float = 6.0
    fumble_lost: float = -2.0
    two_pt_conversion: float = 2.0

class FantasyCalculator:
    def __init__(self, scoring: FantasyScoring = None):
        self.scoring = scoring or FantasyScoring()

    def calculate_qb_points(self, stats) -> float:
        """Calculate fantasy points for a quarterback."""
        points = 0.0

        # Passing
        points += getattr(stats, 'passing_yards', 0) * self.scoring.passing_yard
        points += getattr(stats, 'passing_touchdowns', 0) * self.scoring.passing_td
        points += getattr(stats, 'interceptions', 0) * self.scoring.interception

        # Rushing (for mobile QBs)
        points += getattr(stats, 'rushing_yards', 0) * self.scoring.rushing_yard
        points += getattr(stats, 'rushing_touchdowns', 0) * self.scoring.rushing_td

        # Fumbles
        points += getattr(stats, 'fumbles_lost', 0) * self.scoring.fumble_lost

        return points

    def calculate_rb_points(self, stats) -> float:
        """Calculate fantasy points for a running back."""
        points = 0.0

        # Rushing
        points += getattr(stats, 'rushing_yards', 0) * self.scoring.rushing_yard
        points += getattr(stats, 'rushing_touchdowns', 0) * self.scoring.rushing_td

        # Receiving
        points += getattr(stats, 'receptions', 0) * self.scoring.reception
        points += getattr(stats, 'receiving_yards', 0) * self.scoring.receiving_yard
        points += getattr(stats, 'receiving_touchdowns', 0) * self.scoring.receiving_td

        # Fumbles
        points += getattr(stats, 'fumbles_lost', 0) * self.scoring.fumble_lost

        return points

    def calculate_wr_te_points(self, stats) -> float:
        """Calculate fantasy points for WR/TE."""
        points = 0.0

        # Receiving
        points += getattr(stats, 'receptions', 0) * self.scoring.reception
        points += getattr(stats, 'receiving_yards', 0) * self.scoring.receiving_yard
        points += getattr(stats, 'receiving_touchdowns', 0) * self.scoring.receiving_td

        # Rushing (rare)
        points += getattr(stats, 'rushing_yards', 0) * self.scoring.rushing_yard
        points += getattr(stats, 'rushing_touchdowns', 0) * self.scoring.rushing_td

        # Fumbles
        points += getattr(stats, 'fumbles_lost', 0) * self.scoring.fumble_lost

        return points

def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})
    calculator = FantasyCalculator()

    # Get stats
    passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)
    rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)
    receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)

    # Calculate QB fantasy points
    print("=== TOP 10 FANTASY QBs ===")
    qb_points = []
    for player in passing.players:
        points = calculator.calculate_qb_points(player)
        qb_points.append((player.player_name, player.team_abbreviation, points))

    qb_points.sort(key=lambda x: x[2], reverse=True)
    for i, (name, team, pts) in enumerate(qb_points[:10], 1):
        print(f"{i:2}. {name} ({team}): {pts:.1f} pts")

    # Calculate RB fantasy points
    print("\n=== TOP 10 FANTASY RBs ===")
    rb_points = []
    for player in rushing.players:
        points = calculator.calculate_rb_points(player)
        rb_points.append((player.player_name, player.team_abbreviation, points))

    rb_points.sort(key=lambda x: x[2], reverse=True)
    for i, (name, team, pts) in enumerate(rb_points[:10], 1):
        print(f"{i:2}. {name} ({team}): {pts:.1f} pts")

    # Calculate WR/TE fantasy points
    print("\n=== TOP 10 FANTASY WR/TEs ===")
    wr_points = []
    for player in receiving.players:
        points = calculator.calculate_wr_te_points(player)
        wr_points.append((player.player_name, player.team_abbreviation, points))

    wr_points.sort(key=lambda x: x[2], reverse=True)
    for i, (name, team, pts) in enumerate(wr_points[:10], 1):
        print(f"{i:2}. {name} ({team}): {pts:.1f} pts")

if __name__ == "__main__":
    main()
```

## Weekly Projections

```python
from griddy.nfl import GriddyNFL
from statistics import mean

def calculate_weekly_average(nfl, player_name: str, position: str, season: int):
    """Calculate weekly average fantasy points."""
    weekly_points = []

    for week in range(1, 18):
        try:
            if position == "QB":
                stats = nfl.stats.passing.get_passing_stats_by_week(
                    season=season, week=week
                )
                player_stats = next(
                    (p for p in stats.players if p.player_name == player_name),
                    None
                )
                if player_stats:
                    points = calculate_qb_points(player_stats)
                    weekly_points.append(points)

            elif position in ["RB", "WR", "TE"]:
                rushing = nfl.stats.rushing.get_rushing_stats_by_week(
                    season=season, week=week
                )
                receiving = nfl.stats.receiving.get_receiving_stats_by_week(
                    season=season, week=week
                )

                # Combine stats
                # (simplified - in practice you'd merge by player ID)

        except Exception:
            continue

    if weekly_points:
        return {
            'average': mean(weekly_points),
            'high': max(weekly_points),
            'low': min(weekly_points),
            'games': len(weekly_points)
        }

    return None
```

## Matchup Analysis

```python
def analyze_matchup(nfl, team: str, opponent: str, season: int):
    """Analyze fantasy matchup against specific opponent."""

    # Get opponent's defensive stats
    team_defense = nfl.stats.team_defense.get_team_defense_stats_by_season(
        season=season
    )

    opp_defense = next(
        (t for t in team_defense.teams if t.team_abbreviation == opponent),
        None
    )

    if not opp_defense:
        return None

    # Analyze defensive weaknesses
    analysis = {
        'opponent': opponent,
        'passing_yards_allowed': opp_defense.passing_yards_allowed,
        'rushing_yards_allowed': opp_defense.rushing_yards_allowed,
        'points_allowed': opp_defense.points_allowed,
    }

    # Rank against league
    passing_rank = sum(
        1 for t in team_defense.teams
        if t.passing_yards_allowed < opp_defense.passing_yards_allowed
    ) + 1

    rushing_rank = sum(
        1 for t in team_defense.teams
        if t.rushing_yards_allowed < opp_defense.rushing_yards_allowed
    ) + 1

    analysis['passing_defense_rank'] = passing_rank
    analysis['rushing_defense_rank'] = rushing_rank

    return analysis

# Usage
nfl = GriddyNFL(nfl_auth={"accessToken": "token"})
matchup = analyze_matchup(nfl, "KC", "LV", 2024)

print(f"Matchup vs {matchup['opponent']}:")
print(f"  Passing yards allowed: {matchup['passing_yards_allowed']}")
print(f"  Passing D rank: #{matchup['passing_defense_rank']}")
print(f"  Rushing yards allowed: {matchup['rushing_yards_allowed']}")
print(f"  Rushing D rank: #{matchup['rushing_defense_rank']}")
```

## Start/Sit Recommendations

```python
from dataclasses import dataclass
from typing import List

@dataclass
class PlayerRecommendation:
    name: str
    team: str
    position: str
    projected_points: float
    matchup_grade: str  # A, B, C, D, F
    recommendation: str  # START, SIT, FLEX

def get_start_sit_recommendations(
    nfl,
    players: List[dict],  # [{name, team, position}]
    week: int,
    season: int = 2024
) -> List[PlayerRecommendation]:
    """Generate start/sit recommendations."""

    recommendations = []

    # Get schedule to find matchups
    games = nfl.games.get_games(
        season=season,
        season_type="REG",
        week=week
    )

    # Map teams to opponents
    matchups = {}
    for game in games.games:
        matchups[game.home_team.abbreviation] = game.away_team.abbreviation
        matchups[game.away_team.abbreviation] = game.home_team.abbreviation

    for player in players:
        opponent = matchups.get(player['team'])

        if not opponent:
            continue

        # Analyze matchup
        matchup_analysis = analyze_matchup(
            nfl, player['team'], opponent, season
        )

        # Calculate projected points (simplified)
        projected = estimate_projection(nfl, player, matchup_analysis, season)

        # Grade matchup
        if player['position'] in ['QB', 'WR', 'TE']:
            rank = matchup_analysis['passing_defense_rank']
        else:
            rank = matchup_analysis['rushing_defense_rank']

        if rank <= 6:
            grade = 'A'
        elif rank <= 12:
            grade = 'B'
        elif rank <= 20:
            grade = 'C'
        elif rank <= 26:
            grade = 'D'
        else:
            grade = 'F'

        # Make recommendation
        if projected >= 15 and grade in ['A', 'B']:
            rec = 'START'
        elif projected <= 8 or grade == 'F':
            rec = 'SIT'
        else:
            rec = 'FLEX'

        recommendations.append(PlayerRecommendation(
            name=player['name'],
            team=player['team'],
            position=player['position'],
            projected_points=projected,
            matchup_grade=grade,
            recommendation=rec
        ))

    return recommendations

def estimate_projection(nfl, player: dict, matchup, season: int) -> float:
    """Estimate fantasy points projection."""
    # Get player's season average
    # (In practice, calculate from weekly stats)

    # Apply matchup adjustment
    # (Simplified: better matchup = higher projection)

    base_projection = 12.0  # Default

    matchup_adjustments = {'A': 1.2, 'B': 1.1, 'C': 1.0, 'D': 0.9, 'F': 0.8}

    # Determine grade from matchup
    if player['position'] in ['QB', 'WR', 'TE']:
        rank = matchup['passing_defense_rank']
    else:
        rank = matchup['rushing_defense_rank']

    if rank <= 6:
        grade = 'A'
    elif rank <= 12:
        grade = 'B'
    elif rank <= 20:
        grade = 'C'
    elif rank <= 26:
        grade = 'D'
    else:
        grade = 'F'

    return base_projection * matchup_adjustments[grade]
```

## Waiver Wire Analysis

```python
def find_waiver_targets(
    nfl,
    rostered_players: List[str],  # Names already rostered
    season: int = 2024,
    min_games: int = 3
) -> List[dict]:
    """Find waiver wire targets based on recent performance."""

    # Get recent stats (last 3 weeks)
    recent_weeks = range(max(1, 18 - 3), 18)

    player_recent_stats = {}

    for week in recent_weeks:
        # Get all stats for the week
        passing = nfl.stats.passing.get_passing_stats_by_week(
            season=season, week=week
        )
        rushing = nfl.stats.rushing.get_rushing_stats_by_week(
            season=season, week=week
        )
        receiving = nfl.stats.receiving.get_receiving_stats_by_week(
            season=season, week=week
        )

        # Aggregate by player
        # (simplified - would need proper player ID matching)

    # Filter to unrostered players with good recent performance
    targets = []
    for name, stats in player_recent_stats.items():
        if name in rostered_players:
            continue

        if stats['games'] < min_games:
            continue

        avg_points = stats['total_points'] / stats['games']

        if avg_points >= 10:  # Threshold for consideration
            targets.append({
                'name': name,
                'position': stats['position'],
                'team': stats['team'],
                'recent_avg': avg_points,
                'trend': stats.get('trend', 'stable')
            })

    # Sort by recent average
    targets.sort(key=lambda x: x['recent_avg'], reverse=True)

    return targets[:10]
```
