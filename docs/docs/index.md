# Griddy - NFL Data SDK

Welcome to the Griddy SDK documentation. Griddy provides a unified interface for accessing NFL data from multiple API endpoints, including game schedules, player statistics, Next Gen Stats, and more.

## Features

- **Unified API**: Single interface for accessing NFL data from multiple sources
- **Type Safety**: Full type hints in Python (Pydantic models) and TypeScript (interfaces)
- **Async Support**: Both synchronous and asynchronous methods (Python) or native async (TypeScript)
- **Lazy Loading**: Sub-SDKs load on demand for fast startup
- **Comprehensive Data**: Games, rosters, standings, player stats, Next Gen Stats, and betting odds

## Available SDKs

=== "Python"

    ```bash
    pip install griddy
    ```

    - Python 3.14+
    - Sync and async methods
    - Pydantic models with validation
    - Browser-based authentication via Playwright

=== "TypeScript"

    ```bash
    npm install griddy-sdk
    ```

    - Node.js 18+
    - Native async/await
    - Full TypeScript type definitions
    - Token-based authentication

## Quick Example

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL

    # Initialize with auth token
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    # Get games for week 1 of the 2024 season
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)

    for game in games.games:
        print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    // Initialize with auth token
    const nfl = new GriddyNFL({ nflAuth: { accessToken: 'your_token' } });

    // Get games for week 1 of the 2024 season
    const games = await nfl.games.getGames(2024, 'REG', 1);

    games.games?.forEach(game => {
      console.log(`${game.awayTeam?.abbreviation} @ ${game.homeTeam?.abbreviation}`);
    });
    ```

## API Categories

### Regular API

Public NFL.com endpoints for core football data:

- **Games**: Schedules, scores, box scores, play-by-play
- **Rosters**: Team rosters and player assignments
- **Standings**: Division and conference standings
- **Draft**: NFL Draft picks and information
- **Combine**: NFL Combine workout data

### Pro API

Advanced statistics and analytics requiring authentication:

- **Stats**: Passing, rushing, receiving, defense statistics
- **Team Stats**: Team offense and defense statistics
- **Betting**: Odds and lines
- **Players**: Player information and projections
- **Transactions**: Player transactions and roster moves

### Next Gen Stats

Player tracking data and advanced analytics:

- **Stats**: Passing, rushing, receiving tracking metrics
- **Leaders**: Fastest ball carriers, longest plays
- **Content**: Charts and highlights
- **League**: Schedules and team information

## Getting Started

<div class="grid cards" markdown>

-   :material-download: **Installation**

    ---

    Install the SDK for your language

    [:octicons-arrow-right-24: Installation](getting-started/installation.md)

-   :material-key: **Authentication**

    ---

    Set up authentication for API access

    [:octicons-arrow-right-24: Authentication](getting-started/authentication.md)

-   :material-language-python: **Python Quickstart**

    ---

    Get started with the Python SDK

    [:octicons-arrow-right-24: Python Quickstart](getting-started/quickstart-python.md)

-   :material-language-typescript: **TypeScript Quickstart**

    ---

    Get started with the TypeScript SDK

    [:octicons-arrow-right-24: TypeScript Quickstart](getting-started/quickstart-typescript.md)

</div>
