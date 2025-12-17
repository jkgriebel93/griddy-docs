# Game Predictions

This example demonstrates how to use NFL data to build simple game prediction models.

## Simple Win Probability

```python
"""
Simple game prediction based on historical data.
"""

from griddy.nfl import GriddyNFL
from collections import defaultdict
from typing import Dict, List, Tuple

def calculate_team_stats(nfl, season: int) -> Dict[str, Dict]:
    """Calculate aggregate team statistics."""
    team_stats = defaultdict(lambda: {
        'wins': 0,
        'losses': 0,
        'points_for': 0,
        'points_against': 0,
        'games': 0
    })

    for week in range(1, 19):
        games = nfl.games.get_games(
            season=season,
            season_type="REG",
            week=week
        )

        for game in games.games:
            if game.game_status not in ["FINAL", "FINAL_OVERTIME"]:
                continue

            home = game.home_team.abbreviation
            away = game.away_team.abbreviation
            home_score = game.home_team.score
            away_score = game.away_team.score

            # Update home team
            team_stats[home]['games'] += 1
            team_stats[home]['points_for'] += home_score
            team_stats[home]['points_against'] += away_score

            # Update away team
            team_stats[away]['games'] += 1
            team_stats[away]['points_for'] += away_score
            team_stats[away]['points_against'] += home_score

            # Record win/loss
            if home_score > away_score:
                team_stats[home]['wins'] += 1
                team_stats[away]['losses'] += 1
            elif away_score > home_score:
                team_stats[away]['wins'] += 1
                team_stats[home]['losses'] += 1

    # Calculate derived stats
    for team, stats in team_stats.items():
        if stats['games'] > 0:
            stats['win_pct'] = stats['wins'] / stats['games']
            stats['ppg'] = stats['points_for'] / stats['games']
            stats['papg'] = stats['points_against'] / stats['games']
            stats['point_diff'] = stats['ppg'] - stats['papg']

    return dict(team_stats)

def predict_winner(
    team_stats: Dict,
    home_team: str,
    away_team: str,
    home_advantage: float = 0.03
) -> Tuple[str, float]:
    """
    Predict game winner using simple win probability.

    Returns (predicted_winner, confidence)
    """
    home_stats = team_stats.get(home_team, {})
    away_stats = team_stats.get(away_team, {})

    home_win_pct = home_stats.get('win_pct', 0.5)
    away_win_pct = away_stats.get('win_pct', 0.5)

    home_point_diff = home_stats.get('point_diff', 0)
    away_point_diff = away_stats.get('point_diff', 0)

    # Simple probability calculation
    # Combine win percentage and point differential
    home_strength = (home_win_pct * 0.6) + ((home_point_diff + 15) / 30 * 0.4)
    away_strength = (away_win_pct * 0.6) + ((away_point_diff + 15) / 30 * 0.4)

    # Add home field advantage
    home_strength += home_advantage

    # Normalize to probabilities
    total = home_strength + away_strength
    home_prob = home_strength / total

    if home_prob > 0.5:
        return home_team, home_prob
    else:
        return away_team, 1 - home_prob

def main():
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    # Use previous season data for predictions
    print("Calculating team stats from 2023 season...")
    team_stats = calculate_team_stats(nfl, 2023)

    # Display team rankings
    print("\n=== Team Rankings by Point Differential ===")
    sorted_teams = sorted(
        team_stats.items(),
        key=lambda x: x[1].get('point_diff', 0),
        reverse=True
    )

    for i, (team, stats) in enumerate(sorted_teams, 1):
        print(f"{i:2}. {team}: +{stats['point_diff']:.1f} "
              f"({stats['wins']}-{stats['losses']})")

    # Make predictions for sample matchups
    print("\n=== Game Predictions ===")
    matchups = [
        ("KC", "DET"),
        ("SF", "DAL"),
        ("BUF", "MIA"),
    ]

    for home, away in matchups:
        winner, confidence = predict_winner(team_stats, home, away)
        print(f"{away} @ {home}: {winner} ({confidence*100:.1f}% confidence)")

if __name__ == "__main__":
    main()
```

## Point Spread Prediction

```python
def predict_spread(
    team_stats: Dict,
    home_team: str,
    away_team: str,
    home_advantage_points: float = 2.5
) -> float:
    """Predict point spread (positive = home favored)."""
    home_stats = team_stats.get(home_team, {})
    away_stats = team_stats.get(away_team, {})

    home_ppg = home_stats.get('ppg', 21)
    home_papg = home_stats.get('papg', 21)
    away_ppg = away_stats.get('ppg', 21)
    away_papg = away_stats.get('papg', 21)

    # Estimate scores
    # Home team scores: average of their offense vs away defense
    home_expected = (home_ppg + away_papg) / 2
    away_expected = (away_ppg + home_papg) / 2

    # Calculate spread
    spread = home_expected - away_expected + home_advantage_points

    return spread

# Usage
spread = predict_spread(team_stats, "KC", "DET")
if spread > 0:
    print(f"KC -{ spread:.1f}")
else:
    print(f"DET -{ abs(spread):.1f}")
```

## Using Statistics for Predictions

```python
from griddy.nfl import GriddyNFL

def get_team_offensive_efficiency(nfl, team: str, season: int) -> float:
    """Calculate team offensive efficiency."""
    team_offense = nfl.stats.team_offense.get_team_offense_stats_by_season(
        season=season
    )

    for t in team_offense.teams:
        if t.team_abbreviation == team:
            # Simple efficiency: points per play estimate
            return t.points_per_game / 10  # Normalize

    return 2.0  # Default

def get_team_defensive_efficiency(nfl, team: str, season: int) -> float:
    """Calculate team defensive efficiency."""
    team_defense = nfl.stats.team_defense.get_team_defense_stats_by_season(
        season=season
    )

    for t in team_defense.teams:
        if t.team_abbreviation == team:
            return t.points_allowed_per_game / 10  # Normalize

    return 2.0  # Default

def predict_game_score(
    nfl,
    home_team: str,
    away_team: str,
    season: int
) -> Tuple[float, float]:
    """Predict game score."""
    home_off = get_team_offensive_efficiency(nfl, home_team, season)
    home_def = get_team_defensive_efficiency(nfl, home_team, season)
    away_off = get_team_offensive_efficiency(nfl, away_team, season)
    away_def = get_team_defensive_efficiency(nfl, away_team, season)

    # Home advantage
    home_advantage = 0.15

    # Predict scores
    home_score = ((home_off + away_def) / 2 + home_advantage) * 10
    away_score = ((away_off + home_def) / 2) * 10

    return home_score, away_score
```

## Historical Accuracy Check

```python
def evaluate_predictions(nfl, season: int, start_week: int = 10):
    """Evaluate prediction accuracy on second half of season."""

    # Build stats from first half of season
    print(f"Building model from weeks 1-{start_week-1}...")
    team_stats = calculate_team_stats_through_week(nfl, season, start_week - 1)

    correct = 0
    total = 0

    # Test on remaining weeks
    for week in range(start_week, 19):
        games = nfl.games.get_games(
            season=season,
            season_type="REG",
            week=week
        )

        for game in games.games:
            if game.game_status not in ["FINAL", "FINAL_OVERTIME"]:
                continue

            home = game.home_team.abbreviation
            away = game.away_team.abbreviation
            home_score = game.home_team.score
            away_score = game.away_team.score

            # Make prediction
            predicted_winner, confidence = predict_winner(team_stats, home, away)

            # Check actual result
            actual_winner = home if home_score > away_score else away

            if predicted_winner == actual_winner:
                correct += 1
            total += 1

    accuracy = correct / total if total > 0 else 0
    print(f"\nPrediction Accuracy: {correct}/{total} ({accuracy*100:.1f}%)")

    return accuracy

def calculate_team_stats_through_week(nfl, season: int, max_week: int) -> Dict:
    """Calculate team stats through a specific week."""
    team_stats = defaultdict(lambda: {
        'wins': 0, 'losses': 0, 'points_for': 0,
        'points_against': 0, 'games': 0
    })

    for week in range(1, max_week + 1):
        games = nfl.games.get_games(
            season=season,
            season_type="REG",
            week=week
        )

        for game in games.games:
            if game.game_status not in ["FINAL", "FINAL_OVERTIME"]:
                continue

            home = game.home_team.abbreviation
            away = game.away_team.abbreviation
            home_score = game.home_team.score
            away_score = game.away_team.score

            team_stats[home]['games'] += 1
            team_stats[home]['points_for'] += home_score
            team_stats[home]['points_against'] += away_score
            team_stats[away]['games'] += 1
            team_stats[away]['points_for'] += away_score
            team_stats[away]['points_against'] += home_score

            if home_score > away_score:
                team_stats[home]['wins'] += 1
                team_stats[away]['losses'] += 1
            else:
                team_stats[away]['wins'] += 1
                team_stats[home]['losses'] += 1

    # Calculate derived stats
    for team, stats in team_stats.items():
        if stats['games'] > 0:
            stats['win_pct'] = stats['wins'] / stats['games']
            stats['ppg'] = stats['points_for'] / stats['games']
            stats['papg'] = stats['points_against'] / stats['games']
            stats['point_diff'] = stats['ppg'] - stats['papg']

    return dict(team_stats)
```

## Machine Learning Integration

```python
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

def build_ml_model(nfl, seasons: list):
    """Build ML model from historical data."""
    data = []

    for season in seasons:
        team_stats = calculate_team_stats(nfl, season)

        for week in range(1, 19):
            games = nfl.games.get_games(
                season=season,
                season_type="REG",
                week=week
            )

            for game in games.games:
                if game.game_status not in ["FINAL", "FINAL_OVERTIME"]:
                    continue

                home = game.home_team.abbreviation
                away = game.away_team.abbreviation

                home_stats = team_stats.get(home, {})
                away_stats = team_stats.get(away, {})

                # Features
                features = {
                    'home_win_pct': home_stats.get('win_pct', 0.5),
                    'away_win_pct': away_stats.get('win_pct', 0.5),
                    'home_point_diff': home_stats.get('point_diff', 0),
                    'away_point_diff': away_stats.get('point_diff', 0),
                    'home_ppg': home_stats.get('ppg', 21),
                    'away_ppg': away_stats.get('ppg', 21),
                }

                # Target: did home team win?
                features['home_win'] = int(
                    game.home_team.score > game.away_team.score
                )

                data.append(features)

    # Create DataFrame
    df = pd.DataFrame(data)

    # Split features and target
    X = df.drop('home_win', axis=1)
    y = df['home_win']

    # Train model
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    model = LogisticRegression()
    model.fit(X_train, y_train)

    # Evaluate
    accuracy = model.score(X_test, y_test)
    print(f"Model accuracy: {accuracy*100:.1f}%")

    return model
```
