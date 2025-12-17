# Players Data Model

This guide covers the player data structures returned by the Griddy SDK.

## Player Information

Players are returned from various endpoints with different levels of detail.

### Basic Player Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique player identifier |
| `esbId` | string | ESB (Elias Sports Bureau) ID |
| `gsisId` | string | GSIS (Game Statistics & Information System) ID |
| `firstName` | string | Player's first name |
| `lastName` | string | Player's last name |
| `displayName` | string | Full display name |
| `position` | string | Position abbreviation (QB, RB, WR, etc.) |
| `jerseyNumber` | number | Jersey number |
| `team` | Team | Current team information |

### Python Example

```python
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

# Get player from roster
rosters = nfl.rosters.get_rosters(team_id="SF", season=2024)

for player in rosters.players:
    print(f"{player.jersey_number} {player.display_name}")
    print(f"  Position: {player.position}")
    print(f"  ID: {player.id}")
```

### TypeScript Example

```typescript
// Player interface from TypeScript SDK
interface Player {
  id?: string;
  esbId?: string;
  gsisId?: string;
  firstName?: string;
  lastName?: string;
  displayName?: string;
  position?: string;
  jerseyNumber?: number;
  team?: Team;
}
```

## Player Statistics

Statistics endpoints return players with their associated stats.

### Passing Statistics

| Field | Type | Description |
|-------|------|-------------|
| `passingYards` | number | Total passing yards |
| `passingTouchdowns` | number | Passing touchdowns |
| `interceptions` | number | Interceptions thrown |
| `completions` | number | Completed passes |
| `attempts` | number | Pass attempts |
| `passerRating` | number | Passer rating |
| `completionPercentage` | number | Completion percentage |

```python
# Get passing stats
passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)

for player in passing.players:
    print(f"{player.player_name}")
    print(f"  Yards: {player.passing_yards}")
    print(f"  TDs: {player.passing_touchdowns}")
    print(f"  Rating: {player.passer_rating}")
```

### Rushing Statistics

| Field | Type | Description |
|-------|------|-------------|
| `rushingYards` | number | Total rushing yards |
| `rushingTouchdowns` | number | Rushing touchdowns |
| `rushingAttempts` | number | Rush attempts |
| `yardsPerAttempt` | number | Yards per rush |
| `longestRush` | number | Longest rush |

```python
# Get rushing stats
rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)

for player in rushing.players:
    print(f"{player.player_name}")
    print(f"  Yards: {player.rushing_yards}")
    print(f"  TDs: {player.rushing_touchdowns}")
    print(f"  YPC: {player.yards_per_attempt}")
```

### Receiving Statistics

| Field | Type | Description |
|-------|------|-------------|
| `receptions` | number | Total receptions |
| `receivingYards` | number | Total receiving yards |
| `receivingTouchdowns` | number | Receiving touchdowns |
| `targets` | number | Times targeted |
| `yardsPerReception` | number | Yards per catch |

```python
# Get receiving stats
receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)

for player in receiving.players:
    print(f"{player.player_name}")
    print(f"  Rec: {player.receptions}")
    print(f"  Yards: {player.receiving_yards}")
    print(f"  TDs: {player.receiving_touchdowns}")
```

## Next Gen Stats Player Data

Next Gen Stats provides advanced tracking metrics.

### NGS Passing

| Field | Type | Description |
|-------|------|-------------|
| `avgTimeToThrow` | number | Average time to throw |
| `avgCompletedAirYards` | number | Average air yards on completions |
| `avgIntendedAirYards` | number | Average intended air yards |
| `aggressiveness` | number | Aggressiveness rating |
| `maxCompletedAirDistance` | number | Longest air distance completion |

```python
# Get NGS passing stats
ngs_passing = nfl.ngs.stats.get_passing_stats(
    season=2024,
    season_type="REG"
)

for player in ngs_passing:
    print(f"{player.player_display_name}")
    print(f"  Avg Time to Throw: {player.avg_time_to_throw}")
    print(f"  Aggressiveness: {player.aggressiveness}")
```

### NGS Rushing

| Field | Type | Description |
|-------|------|-------------|
| `efficiency` | number | Rush efficiency |
| `avgRushYards` | number | Average rush yards |
| `rushYardsOverExpected` | number | Yards over expected |
| `avgTimeToLos` | number | Avg time to line of scrimmage |

### NGS Receiving

| Field | Type | Description |
|-------|------|-------------|
| `avgCushion` | number | Average cushion from defender |
| `avgSeparation` | number | Average separation |
| `avgIntendedAirYards` | number | Average intended air yards |
| `catchPercentage` | number | Catch percentage |

## Player Positions

Common position abbreviations:

| Position | Description |
|----------|-------------|
| QB | Quarterback |
| RB | Running Back |
| FB | Fullback |
| WR | Wide Receiver |
| TE | Tight End |
| OT | Offensive Tackle |
| OG | Offensive Guard |
| C | Center |
| DE | Defensive End |
| DT | Defensive Tackle |
| LB | Linebacker |
| CB | Cornerback |
| S | Safety |
| K | Kicker |
| P | Punter |
| LS | Long Snapper |

## Working with Player IDs

Different systems use different player identifiers:

```python
# Player IDs
player_id = "00-0036945"      # NFL ID
esb_id = "GRI123456"          # ESB ID
gsis_id = "00-0036945"        # GSIS ID

# Use the appropriate ID for each endpoint
player = nfl.players.get_player(player_id=player_id)
```

## Filtering and Searching

```python
# Search for players
results = nfl.players.search_players(query="Mahomes")

# Filter by position in results
qbs = [p for p in results if p.position == "QB"]
```
