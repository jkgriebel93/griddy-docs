# Basic Usage

Fundamental patterns for using the Griddy TypeScript SDK.

## SDK Initialization

```typescript
import { GriddyNFL } from "griddy-sdk";

// Initialize with access token
const nfl = new GriddyNFL({
  nflAuth: {
    accessToken: "your_access_token",
  },
});
```

### With Options

```typescript
const nfl = new GriddyNFL({
  nflAuth: {
    accessToken: "your_access_token",
    refreshToken: "optional_refresh_token",
    expiresIn: 3600,
  },
  timeoutMs: 30000,
  debug: true,
});
```

## Fetching Games

### Get Games by Week

```typescript
import { GriddyNFL } from "griddy-sdk";

async function getWeeklyGames() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    // Get Week 1 regular season games for 2024
    const games = await nfl.games.getGames(2024, "REG", 1);

    console.log(`Found ${games.games?.length ?? 0} games`);

    for (const game of games.games ?? []) {
      console.log(`${game.awayTeam?.nickName} @ ${game.homeTeam?.nickName}`);
    }
  } finally {
    nfl.close();
  }
}

getWeeklyGames();
```

### Get Box Score

```typescript
async function getGameBoxScore(gameId: string) {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScore = await nfl.games.getBoxScore(gameId);

    console.log("Home Team:", boxScore.homeTeam);
    console.log("Away Team:", boxScore.awayTeam);
    console.log("Scoring Summary:", boxScore.scoringSummary);
  } finally {
    nfl.close();
  }
}
```

### Get Play-by-Play

```typescript
async function getPlayByPlay(gameId: string) {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const pbp = await nfl.games.getPlayByPlay(
      gameId,
      true,  // includePenalties
      false  // includeFormations
    );

    console.log(`Total plays: ${pbp.plays?.length ?? 0}`);
    console.log(`Total drives: ${pbp.drives?.length ?? 0}`);
  } finally {
    nfl.close();
  }
}
```

## Season Types

Use string literals for season types:

```typescript
// Preseason
const preseasonGames = await nfl.games.getGames(2024, "PRE", 1);

// Regular season
const regularGames = await nfl.games.getGames(2024, "REG", 1);

// Postseason
const playoffGames = await nfl.games.getGames(2024, "POST", 1);
```

## Request Options

All methods accept optional request options:

```typescript
const games = await nfl.games.getGames(2024, "REG", 1, false, {
  timeoutMs: 60000,
  httpHeaders: {
    "X-Custom-Header": "value",
  },
});
```

## Working with Responses

### Type-Safe Access

```typescript
interface GameInfo {
  id: string;
  homeTeam: string;
  awayTeam: string;
  homeScore: number;
  awayScore: number;
}

async function parseGames(): Promise<GameInfo[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const response = await nfl.games.getGames(2024, "REG", 1);

    return (response.games ?? []).map((game) => ({
      id: game.gameId ?? "",
      homeTeam: game.homeTeam?.nickName ?? "Unknown",
      awayTeam: game.awayTeam?.nickName ?? "Unknown",
      homeScore: game.homeTeam?.score ?? 0,
      awayScore: game.awayTeam?.score ?? 0,
    }));
  } finally {
    nfl.close();
  }
}
```

### Null Checking with Optional Chaining

```typescript
const games = await nfl.games.getGames(2024, "REG", 1);

// Safe access with optional chaining and nullish coalescing
const firstGame = games.games?.[0];
const homeTeamName = firstGame?.homeTeam?.nickName ?? "TBD";
const gameTime = firstGame?.gameTime ?? "Not scheduled";
```

## Complete Example

```typescript
import { GriddyNFL } from "griddy-sdk";

async function main() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
    timeoutMs: 30000,
  });

  try {
    // Get all Week 1 games
    const games = await nfl.games.getGames(2024, "REG", 1);

    console.log("=== Week 1 Games ===\n");

    for (const game of games.games ?? []) {
      const status = game.gameStatus ?? "Unknown";
      const away = game.awayTeam;
      const home = game.homeTeam;

      console.log(`${away?.nickName} (${away?.score ?? 0}) @ ${home?.nickName} (${home?.score ?? 0})`);
      console.log(`  Status: ${status}`);
      console.log(`  Game ID: ${game.gameId}`);
      console.log();

      // Get box score for completed games
      if (status === "FINAL" && game.gameId) {
        const boxScore = await nfl.games.getBoxScore(game.gameId);
        console.log("  Box Score loaded successfully");
      }
    }
  } catch (error) {
    console.error("Error:", error);
  } finally {
    nfl.close();
  }
}

main();
```

## Next Steps

- [Async Patterns](async-patterns.md) - Advanced async/await patterns
- [Testing Strategies](testing-strategies.md) - Testing your integration
