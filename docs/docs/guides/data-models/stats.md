# Statistics Data Model

This guide covers the statistics data structures returned by the Griddy SDK.

## Overview

The SDK provides access to multiple types of statistics:

- **Pro API Stats**: Traditional box score statistics
- **Next Gen Stats**: Advanced player tracking metrics

## Pro API Statistics

### Accessing Statistics

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Player statistics
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)
rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)
receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)
defense = nfl.stats.defense.get_defensive_stats_by_season(season=2024)

# Team statistics
team_offense = nfl.stats.team_offense.get_team_offense_stats_by_season(season=2024)
team_defense = nfl.stats.team_defense.get_team_defense_stats_by_season(season=2024)

# Fantasy statistics
fantasy = nfl.stats.fantasy.get_fantasy_stats(season=2024)
```

### Passing Statistics

| Field | Type | Description |
|-------|------|-------------|
| `passingYards` | number | Total passing yards |
| `passingTouchdowns` | number | Passing touchdowns |
| `interceptions` | number | Interceptions thrown |
| `completions` | number | Completed passes |
| `attempts` | number | Pass attempts |
| `passerRating` | number | Passer rating (0-158.3) |
| `completionPercentage` | number | Completion percentage |
| `yardsPerAttempt` | number | Yards per attempt |
| `sacks` | number | Times sacked |
| `sackYardsLost` | number | Yards lost to sacks |

```python
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)

for p in passing.players[:10]:  # Top 10
    print(f"{p.player_name} ({p.team_abbreviation})")
    print(f"  {p.completions}/{p.attempts} ({p.completion_percentage:.1f}%)")
    print(f"  {p.passing_yards} yds, {p.passing_touchdowns} TD, {p.interceptions} INT")
    print(f"  Rating: {p.passer_rating:.1f}")
```

### Rushing Statistics

| Field | Type | Description |
|-------|------|-------------|
| `rushingYards` | number | Total rushing yards |
| `rushingTouchdowns` | number | Rushing touchdowns |
| `rushingAttempts` | number | Rush attempts |
| `yardsPerAttempt` | number | Yards per rush |
| `longestRush` | number | Longest rush |
| `fumbles` | number | Fumbles |
| `fumblesLost` | number | Fumbles lost |

```python
rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)

for p in rushing.players[:10]:
    print(f"{p.player_name}: {p.rushing_yards} yds on {p.rushing_attempts} att")
    print(f"  {p.yards_per_attempt:.1f} YPC, {p.rushing_touchdowns} TD")
```

### Receiving Statistics

| Field | Type | Description |
|-------|------|-------------|
| `receptions` | number | Total receptions |
| `receivingYards` | number | Total receiving yards |
| `receivingTouchdowns` | number | Receiving touchdowns |
| `targets` | number | Times targeted |
| `yardsPerReception` | number | Yards per catch |
| `catchPercentage` | number | Catch percentage |
| `longestReception` | number | Longest reception |

```python
receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)

for p in receiving.players[:10]:
    print(f"{p.player_name}: {p.receptions} rec, {p.receiving_yards} yds")
    print(f"  {p.receiving_touchdowns} TD, {p.yards_per_reception:.1f} YPR")
```

### Defensive Statistics

| Field | Type | Description |
|-------|------|-------------|
| `tackles` | number | Total tackles |
| `sacks` | number | Sacks |
| `interceptions` | number | Interceptions |
| `forcedFumbles` | number | Forced fumbles |
| `passesDefended` | number | Passes defended |
| `tacklesForLoss` | number | Tackles for loss |
| `qbHits` | number | QB hits |

```python
defense = nfl.stats.defense.get_defensive_stats_by_season(season=2024)

for p in defense.players[:10]:
    print(f"{p.player_name}: {p.tackles} tackles, {p.sacks} sacks")
    print(f"  {p.interceptions} INT, {p.passes_defended} PD")
```

### Team Statistics

```python
# Team offense
team_off = nfl.stats.team_offense.get_team_offense_stats_by_season(season=2024)

for team in team_off.teams:
    print(f"{team.team_name}")
    print(f"  Points/Game: {team.points_per_game:.1f}")
    print(f"  Total Yards: {team.total_yards}")
    print(f"  Passing: {team.passing_yards}, Rushing: {team.rushing_yards}")

# Team defense
team_def = nfl.stats.team_defense.get_team_defense_stats_by_season(season=2024)

for team in team_def.teams:
    print(f"{team.team_name}")
    print(f"  Points Allowed/Game: {team.points_allowed_per_game:.1f}")
    print(f"  Yards Allowed: {team.total_yards_allowed}")
```

## Next Gen Stats

Next Gen Stats provide advanced tracking data from player sensors.

### Accessing NGS

```python
# Passing stats
ngs_passing = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG"
)

# Rushing stats
ngs_rushing = nfl.ngs.stats.get_rushing_stats(
    season=2024,
    season_type="REG"
)

# Receiving stats
ngs_receiving = nfl.ngs.stats.get_receiving_stats(
    season=2024,
    season_type="REG"
)

# Weekly stats
weekly = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG",
    week=12
)
```

### NGS Passing Metrics

| Field | Type | Description |
|-------|------|-------------|
| `avgTimeToThrow` | number | Average time to throw (seconds) |
| `avgCompletedAirYards` | number | Avg air yards on completions |
| `avgIntendedAirYards` | number | Avg intended air yards |
| `aggressiveness` | number | Aggressiveness rating |
| `maxCompletedAirDistance` | number | Longest air distance completion |
| `avgAirYardsDifferential` | number | Air yards differential |
| `completionPercentageAboveExpected` | number | Completion % above expected |

```python
for p in ngs_passing:
    print(f"{p.player_display_name}")
    print(f"  Time to Throw: {p.avg_time_to_throw:.2f}s")
    print(f"  Aggressiveness: {p.aggressiveness:.1f}%")
    print(f"  Air Yards: {p.avg_intended_air_yards:.1f}")
```

### NGS Rushing Metrics

| Field | Type | Description |
|-------|------|-------------|
| `efficiency` | number | Rush efficiency |
| `rushYardsOverExpected` | number | Yards over expected |
| `rushYardsOverExpectedPerAtt` | number | RYOE per attempt |
| `avgTimeToLos` | number | Avg time to line of scrimmage |
| `rushPctOverEight` | number | % of rushes over 8 yards |

### NGS Receiving Metrics

| Field | Type | Description |
|-------|------|-------------|
| `avgCushion` | number | Avg cushion from defender |
| `avgSeparation` | number | Avg separation from defender |
| `avgIntendedAirYards` | number | Avg intended air yards |
| `percentShareOfIntendedAirYards` | number | Share of team air yards |
| `catchPercentage` | number | Catch percentage |

## Leaders

Get statistical leaderboards:

```python
# Fastest ball carriers
fastest = nfl.ngs.leaders.get_fastest_ball_carriers(
    season=2024,
    season_type="REG",
    limit=10
)

# Longest plays
longest = nfl.ngs.leaders.get_longest_plays(
    season=2024,
    season_type="REG",
    limit=10
)

for play in fastest:
    print(f"{play.player_name}: {play.max_speed:.1f} mph")
```

## Season Type

All statistics can be filtered by season type:

| Value | Description |
|-------|-------------|
| `PRE` | Preseason stats |
| `REG` | Regular season stats |
| `POST` | Postseason stats |

```python
# Regular season stats
reg_stats = nfl.stats.passing.get_passing_stats_by_season(
    season=2024,
    season_type="REG"
)

# Playoff stats
post_stats = nfl.stats.passing.get_passing_stats_by_season(
    season=2024,
    season_type="POST"
)
```

## Weekly Statistics

Get stats for a specific week:

```python
# Week-specific stats
week1_passing = nfl.stats.passing.get_passing_stats_by_week(
    season=2024,
    week=1
)

# NGS weekly
ngs_week1 = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG",
    week=1
)
```
