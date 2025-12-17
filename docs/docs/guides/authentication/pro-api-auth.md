# Pro API Authentication

The Pro API provides access to advanced statistics, betting odds, and other premium data. This guide covers authentication requirements for Pro API endpoints.

## Overview

Pro API endpoints include:

- **Stats**: Detailed passing, rushing, receiving, and defensive statistics
- **Betting**: Odds and betting lines
- **Players**: Player projections and advanced metrics
- **Transactions**: Player transactions and roster moves
- **Fantasy**: Fantasy football statistics

## Authentication Requirements

Pro API endpoints require the same authentication as regular endpoints, but may have additional access requirements based on your NFL.com account type.

### Using Pro API Endpoints

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL

    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    # Access Pro API statistics
    passing = nfl.stats.passing.get_passing_stats_by_season(season=2024)
    rushing = nfl.stats.rushing.get_rushing_stats_by_season(season=2024)
    receiving = nfl.stats.receiving.get_receiving_stats_by_season(season=2024)
    defense = nfl.stats.defense.get_defensive_stats_by_season(season=2024)

    # Team statistics
    team_offense = nfl.stats.team_offense.get_team_offense_stats_by_season(season=2024)
    team_defense = nfl.stats.team_defense.get_team_defense_stats_by_season(season=2024)

    # Betting odds
    odds = nfl.betting.get_odds(game_id="game-uuid")

    # Player information
    player = nfl.players.get_player(player_id="player-id")

    # Transactions
    transactions = nfl.transactions.get_transactions(season=2024)
    ```

=== "TypeScript"

    ```typescript
    // Note: Pro API endpoints are being ported to TypeScript
    // Currently only Games endpoint is available

    import { GriddyNFL } from 'griddy-sdk';

    const nfl = new GriddyNFL({ nflAuth: { accessToken: 'your_token' } });

    // Games endpoint is available
    const games = await nfl.games.getGames(2024, 'REG', 1);
    ```

## Available Pro API Endpoints

### Statistics

```python
# Player passing stats
nfl.stats.passing.get_passing_stats_by_season(season=2024)
nfl.stats.passing.get_passing_stats_by_week(season=2024, week=1)

# Player rushing stats
nfl.stats.rushing.get_rushing_stats_by_season(season=2024)
nfl.stats.rushing.get_rushing_stats_by_week(season=2024, week=1)

# Player receiving stats
nfl.stats.receiving.get_receiving_stats_by_season(season=2024)
nfl.stats.receiving.get_receiving_stats_by_week(season=2024, week=1)

# Player defensive stats
nfl.stats.defense.get_defensive_stats_by_season(season=2024)
nfl.stats.defense.get_defensive_stats_by_week(season=2024, week=1)

# Team stats
nfl.stats.team_offense.get_team_offense_stats_by_season(season=2024)
nfl.stats.team_defense.get_team_defense_stats_by_season(season=2024)

# Fantasy stats
nfl.stats.fantasy.get_fantasy_stats(season=2024)
```

### Content

```python
# Game previews and analysis
nfl.content.get_game_preview(game_id="game-uuid")
nfl.content.get_film_cards(game_id="game-uuid")
```

### Players

```python
# Player information
nfl.players.get_player(player_id="player-id")
nfl.players.search_players(query="Patrick Mahomes")
```

### Betting

```python
# Betting odds
nfl.betting.get_odds(game_id="game-uuid")
nfl.betting.get_game_lines(season=2024, week=1)
```

### Transactions

```python
# Player transactions
nfl.transactions.get_transactions(season=2024)
nfl.transactions.get_team_transactions(team_id="KC", season=2024)
```

## Error Handling

Pro API requests may fail due to:

- Invalid or expired token
- Insufficient account permissions
- Rate limiting

```python
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import (
    AuthenticationError,
    GriddyError
)

nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

try:
    stats = nfl.stats.passing.get_passing_stats_by_season(season=2024)
except AuthenticationError:
    print("Authentication failed - check your token")
except GriddyError as e:
    print(f"API error: {e.message}")
    if e.status_code == 403:
        print("Access denied - your account may not have Pro API access")
```

## Best Practices

1. **Verify access**: Test Pro API endpoints to confirm your account has access
2. **Handle errors**: Always handle authentication and permission errors
3. **Cache results**: Pro API data doesn't change frequently, cache when appropriate
4. **Respect limits**: Be mindful of rate limits on Pro API endpoints
