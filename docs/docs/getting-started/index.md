# Getting Started

This guide will help you get up and running with the Griddy NFL SDK quickly.

## Prerequisites

Before you begin, ensure you have:

- **Python 3.14+** or **Node.js 18+**
- An NFL.com account for obtaining authentication tokens

## Quick Installation

=== "Python"

    ```bash
    pip install griddy
    ```

    For development with all dependencies:

    ```bash
    pip install griddy[dev]
    ```

=== "TypeScript"

    ```bash
    npm install griddy-sdk
    ```

    Or with yarn:

    ```bash
    yarn add griddy-sdk
    ```

## Your First API Call

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL

    # Initialize with your auth token
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

    # Get games for a specific week
    games = nfl.games.get_games(
        season=2024,
        season_type="REG",
        week=1
    )

    # Print game matchups
    for game in games.games:
        home = game.home_team.abbreviation
        away = game.away_team.abbreviation
        print(f"{away} @ {home}")
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    // Initialize with your auth token
    const nfl = new GriddyNFL({
      nflAuth: { accessToken: 'your_token' }
    });

    // Get games for a specific week
    const games = await nfl.games.getGames(2024, 'REG', 1);

    // Print game matchups
    games.games?.forEach(game => {
      const home = game.homeTeam?.abbreviation;
      const away = game.awayTeam?.abbreviation;
      console.log(`${away} @ ${home}`);
    });

    // Clean up when done
    nfl.close();
    ```

## Next Steps

<div class="grid cards" markdown>

-   [:octicons-download-16: **Installation**](installation.md)

    Complete installation guide with all options

-   [:octicons-key-16: **Authentication**](authentication.md)

    Learn how to obtain and use authentication tokens

-   [:octicons-code-16: **Python Quickstart**](quickstart-python.md)

    Comprehensive Python SDK walkthrough

-   [:octicons-code-16: **TypeScript Quickstart**](quickstart-typescript.md)

    Comprehensive TypeScript SDK walkthrough

-   [:octicons-question-16: **Choosing an SDK**](choosing-sdk.md)

    Compare Python and TypeScript SDKs

</div>
