# Examples

This section contains practical code examples demonstrating common use cases with the Griddy SDK.

## Python Examples

- [Basic Usage](python/basic-usage.md) - Getting started with core SDK functionality
- [Async Patterns](python/async-patterns.md) - Asynchronous programming patterns
- [Testing Strategies](python/testing-strategies.md) - Testing code that uses the SDK
- [Fetching Player Stats](python/fetch-player-stats.md) - Working with player statistics
- [Game Predictions](python/game-predictions.md) - Building prediction models
- [Fantasy Integration](python/fantasy-integration.md) - Fantasy football applications

## Quick Reference

### Get Games

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})
games = nfl.games.get_games(season=2024, season_type="REG", week=1)
```

### Get Player Stats

```python
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)
rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)
receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)
```

### Get Next Gen Stats

```python
ngs_passing = nfl.ngs.stats.get_passing_stats(season=2024, season_type="REG")
ngs_rushing = nfl.ngs.stats.get_rushing_stats(season=2024, season_type="REG")
```

### Get Box Score

```python
box_score = nfl.games.get_box_score(game_id="game-uuid")
```

### Get Play-by-Play

```python
pbp = nfl.games.get_play_by_play(
    game_id="game-uuid",
    include_penalties=True
)
```
