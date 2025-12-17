# Tutorial: First API Call

This tutorial walks you through making your first API call with the Griddy SDK.

## Prerequisites

- Python 3.14+ or Node.js 18+
- An NFL.com account

## Step 1: Install the SDK

=== "Python"

    ```bash
    pip install griddy
    ```

=== "TypeScript"

    ```bash
    npm install griddy-sdk
    ```

## Step 2: Obtain an Authentication Token

Before using the SDK, you need an NFL access token:

1. Log in to [NFL.com](https://www.nfl.com) in your browser
2. Open Developer Tools (F12)
3. Go to the Network tab
4. Look for requests to `api.nfl.com`
5. Find the `Authorization` header and copy the token after "Bearer "

Save your token:

```bash
export NFL_ACCESS_TOKEN="your_token_here"
```

## Step 3: Create Your First Script

=== "Python"

    Create a file called `first_call.py`:

    ```python
    import os
    from griddy.nfl import GriddyNFL

    # Get token from environment
    token = os.environ.get("NFL_ACCESS_TOKEN")
    if not token:
        print("Please set NFL_ACCESS_TOKEN environment variable")
        exit(1)

    # Initialize the SDK
    nfl = GriddyNFL(nfl_auth={"accessToken": token})

    # Make your first API call
    print("Fetching Week 1 games...")
    games = nfl.games.get_games(
        season=2024,
        season_type="REG",
        week=1
    )

    # Display results
    print(f"\nFound {len(games.games)} games:\n")

    for game in games.games:
        home = game.home_team
        away = game.away_team
        print(f"{away.abbreviation} @ {home.abbreviation} - {game.game_status}")
    ```

=== "TypeScript"

    Create a file called `firstCall.ts`:

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    async function main() {
      // Get token from environment
      const token = process.env.NFL_ACCESS_TOKEN;
      if (!token) {
        console.log("Please set NFL_ACCESS_TOKEN environment variable");
        process.exit(1);
      }

      // Initialize the SDK
      const nfl = new GriddyNFL({ nflAuth: { accessToken: token } });

      try {
        // Make your first API call
        console.log("Fetching Week 1 games...");
        const games = await nfl.games.getGames(2024, 'REG', 1);

        // Display results
        console.log(`\nFound ${games.games?.length ?? 0} games:\n`);

        games.games?.forEach(game => {
          const home = game.homeTeam;
          const away = game.awayTeam;
          console.log(`${away?.abbreviation} @ ${home?.abbreviation} - ${game.gameStatus}`);
        });
      } finally {
        nfl.close();
      }
    }

    main();
    ```

## Step 4: Run Your Script

=== "Python"

    ```bash
    python first_call.py
    ```

=== "TypeScript"

    ```bash
    npx ts-node firstCall.ts
    ```

You should see output like:

```
Fetching Week 1 games...

Found 16 games:

BAL @ KC - FINAL
GB @ PHI - FINAL
...
```

## Step 5: Explore the Response

Let's look at what data is available in the response:

=== "Python"

    ```python
    # Get detailed game info
    game = games.games[0]

    print(f"Game ID: {game.id}")
    print(f"Season: {game.season}")
    print(f"Week: {game.week}")
    print(f"Status: {game.game_status}")

    print(f"\nHome Team:")
    print(f"  Name: {game.home_team.full_name}")
    print(f"  Abbreviation: {game.home_team.abbreviation}")
    print(f"  Score: {game.home_team.score}")

    print(f"\nAway Team:")
    print(f"  Name: {game.away_team.full_name}")
    print(f"  Abbreviation: {game.away_team.abbreviation}")
    print(f"  Score: {game.away_team.score}")
    ```

=== "TypeScript"

    ```typescript
    const game = games.games?.[0];
    if (game) {
      console.log(`Game ID: ${game.id}`);
      console.log(`Season: ${game.season}`);
      console.log(`Week: ${game.week}`);
      console.log(`Status: ${game.gameStatus}`);

      console.log(`\nHome Team:`);
      console.log(`  Name: ${game.homeTeam?.fullName}`);
      console.log(`  Abbreviation: ${game.homeTeam?.abbreviation}`);
      console.log(`  Score: ${game.homeTeam?.score}`);

      console.log(`\nAway Team:`);
      console.log(`  Name: ${game.awayTeam?.fullName}`);
      console.log(`  Abbreviation: ${game.awayTeam?.abbreviation}`);
      console.log(`  Score: ${game.awayTeam?.score}`);
    }
    ```

## Step 6: Add Error Handling

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL
    from griddy.core.exceptions import (
        GriddyError,
        AuthenticationError
    )

    try:
        nfl = GriddyNFL(nfl_auth={"accessToken": token})
        games = nfl.games.get_games(season=2024, season_type="REG", week=1)

        for game in games.games:
            print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")

    except AuthenticationError:
        print("Authentication failed. Your token may be expired.")
        print("Please obtain a new token from NFL.com")

    except GriddyError as e:
        print(f"API Error: {e.message}")
        if e.status_code:
            print(f"Status code: {e.status_code}")
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL, GriddyNFLDefaultError } from 'griddy-sdk';

    try {
      const nfl = new GriddyNFL({ nflAuth: { accessToken: token } });
      const games = await nfl.games.getGames(2024, 'REG', 1);

      games.games?.forEach(game => {
        console.log(`${game.awayTeam?.abbreviation} @ ${game.homeTeam?.abbreviation}`);
      });

      nfl.close();
    } catch (error) {
      if (error instanceof GriddyNFLDefaultError) {
        console.error(`API Error: ${error.message}`);
        if (error.statusCode === 401) {
          console.error("Authentication failed. Your token may be expired.");
        }
      } else {
        throw error;
      }
    }
    ```

## What's Next?

Now that you've made your first API call, try:

- [Game Stats Dashboard](game-stats-dashboard.md) - Build a stats dashboard
- [Live Score Tracker](live-score-tracker.md) - Create a live score tracker
- [Player Comparison](player-comparison.md) - Compare player stats

## Complete Code

=== "Python"

    ```python
    #!/usr/bin/env python3
    """First Griddy SDK API call."""

    import os
    from griddy.nfl import GriddyNFL
    from griddy.core.exceptions import GriddyError, AuthenticationError

    def main():
        # Get token
        token = os.environ.get("NFL_ACCESS_TOKEN")
        if not token:
            print("Please set NFL_ACCESS_TOKEN environment variable")
            return

        try:
            # Initialize and make request
            with GriddyNFL(nfl_auth={"accessToken": token}) as nfl:
                games = nfl.games.get_games(
                    season=2024,
                    season_type="REG",
                    week=1
                )

                print(f"Found {len(games.games)} games:\n")

                for game in games.games:
                    status = game.game_status
                    home = game.home_team
                    away = game.away_team

                    if status in ["FINAL", "FINAL_OVERTIME"]:
                        print(f"{away.abbreviation} {away.score} @ "
                              f"{home.abbreviation} {home.score} - {status}")
                    else:
                        print(f"{away.abbreviation} @ {home.abbreviation} - {status}")

        except AuthenticationError:
            print("Authentication failed. Please check your token.")
        except GriddyError as e:
            print(f"Error: {e.message}")

    if __name__ == "__main__":
        main()
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL, GriddyNFLDefaultError } from 'griddy-sdk';

    async function main() {
      const token = process.env.NFL_ACCESS_TOKEN;
      if (!token) {
        console.log("Please set NFL_ACCESS_TOKEN environment variable");
        return;
      }

      const nfl = new GriddyNFL({ nflAuth: { accessToken: token } });

      try {
        const games = await nfl.games.getGames(2024, 'REG', 1);

        console.log(`Found ${games.games?.length ?? 0} games:\n`);

        games.games?.forEach(game => {
          const status = game.gameStatus;
          const home = game.homeTeam;
          const away = game.awayTeam;

          if (status === 'FINAL' || status === 'FINAL_OVERTIME') {
            console.log(`${away?.abbreviation} ${away?.score} @ ` +
                       `${home?.abbreviation} ${home?.score} - ${status}`);
          } else {
            console.log(`${away?.abbreviation} @ ${home?.abbreviation} - ${status}`);
          }
        });
      } catch (error) {
        if (error instanceof GriddyNFLDefaultError) {
          if (error.statusCode === 401) {
            console.error("Authentication failed. Please check your token.");
          } else {
            console.error(`Error: ${error.message}`);
          }
        } else {
          throw error;
        }
      } finally {
        nfl.close();
      }
    }

    main();
    ```
