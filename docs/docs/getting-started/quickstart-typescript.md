# TypeScript Quickstart

This guide provides a comprehensive walkthrough of using the Griddy TypeScript SDK.

## Installation

```bash
npm install griddy-sdk
```

Or with yarn:

```bash
yarn add griddy-sdk
```

## Basic Usage

### Initializing the Client

```typescript
import { GriddyNFL } from 'griddy-sdk';

// Initialize with auth token (required)
const nfl = new GriddyNFL({
  nflAuth: { accessToken: 'your_token' }
});
```

!!! note "No Browser Authentication"
    Unlike the Python SDK, the TypeScript SDK does not support browser-based authentication. You must provide a pre-obtained access token.

### Getting Game Data

```typescript
import { GriddyNFL } from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'your_token' } });

// Get games for a specific week
const games = await nfl.games.getGames(
  2024,    // season
  'REG',   // seasonType: 'PRE' | 'REG' | 'POST'
  1        // week
);

// Iterate through games
games.games?.forEach(game => {
  console.log(`Game ID: ${game.id}`);
  console.log(`  ${game.awayTeam?.abbreviation} @ ${game.homeTeam?.abbreviation}`);
  console.log(`  Status: ${game.gameStatus}`);
});

// Clean up when done
nfl.close();
```

### Box Scores

```typescript
// Get detailed box score for a game
const boxScore = await nfl.games.getBoxScore('game-uuid-here');

console.log(`Home Team Stats:`, boxScore.homeTeam);
console.log(`Away Team Stats:`, boxScore.awayTeam);
```

### Play-by-Play

```typescript
// Get play-by-play data
const pbp = await nfl.games.getPlayByPlay(
  'game-uuid-here',
  true,   // includePenalties
  false   // includeFormations
);

pbp.plays?.forEach(play => {
  console.log(`Q${play.quarter} - ${play.description}`);
});
```

### Live Game Stats

```typescript
// Get live statistics for games
const liveStats = await nfl.games.getLiveGameStats(2024, 'REG', 1);

liveStats.data?.forEach(game => {
  console.log(game);
});
```

### Weekly Game Details

```typescript
// Get detailed game information with optional extras
const details = await nfl.games.getWeeklyGameDetails(
  2024,    // season
  'REG',   // type
  1,       // week
  true,    // includeDriveChart
  true,    // includeReplays
  true,    // includeStandings
  false    // includeTaggedVideos
);

details.forEach(detail => {
  console.log('Game:', detail.game);
  console.log('Drive Chart:', detail.driveChart);
});
```

## Type Safety

The SDK provides full TypeScript type definitions:

```typescript
import type {
  FootballGamesResponse,
  SeasonTypeEnum
} from 'griddy-sdk';

// Types are inferred from method returns
const games: FootballGamesResponse = await nfl.games.getGames(2024, 'REG', 1);

// Season types are strictly typed
const seasonType: SeasonTypeEnum = 'REG'; // 'PRE' | 'REG' | 'POST'
```

## Error Handling

```typescript
import {
  GriddyNFL,
  GriddyNFLError,
  GriddyNFLDefaultError,
  NoResponseError
} from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'your_token' } });

try {
  const games = await nfl.games.getGames(2024, 'REG', 1);
} catch (error) {
  if (error instanceof GriddyNFLDefaultError) {
    // API returned an error response
    console.error('API Error:', error.message);
    console.error('Status Code:', error.statusCode);
    console.error('Response:', error.responseText);

    // Handle specific status codes
    if (error.statusCode === 401) {
      console.error('Authentication failed - token may be expired');
    } else if (error.statusCode === 404) {
      console.error('Resource not found');
    } else if (error.statusCode === 429) {
      console.error('Rate limited - slow down requests');
    }
  } else if (error instanceof NoResponseError) {
    // No response received (network error, timeout, etc.)
    console.error('No response received from API');
  } else if (error instanceof GriddyNFLError) {
    // Other SDK error
    console.error('SDK Error:', error.message);
  } else {
    // Unknown error
    console.error('Unexpected error:', error);
  }
} finally {
  nfl.close();
}
```

## Configuration Options

### Custom Timeout

```typescript
const nfl = new GriddyNFL({
  nflAuth: { accessToken: 'your_token' },
  timeoutMs: 60000  // 60 seconds
});
```

### Per-Request Options

```typescript
import { createRetryConfig } from 'griddy-sdk';

// Override settings for individual requests
const games = await nfl.games.getGames(2024, 'REG', 1, false, {
  timeoutMs: 30000,
  httpHeaders: { 'X-Custom-Header': 'value' },
  retries: createRetryConfig({
    maxRetries: 5,
    initialDelayMs: 1000,
    maxDelayMs: 30000,
    backoffMultiplier: 2
  })
});
```

## Resource Cleanup

Always close the client when done to release resources:

```typescript
const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

try {
  const games = await nfl.games.getGames(2024, 'REG', 1);
  // Process games...
} finally {
  nfl.close();
}
```

## Complete Example

```typescript
import { GriddyNFL, GriddyNFLError } from 'griddy-sdk';

async function main() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: 'your_token' },
    timeoutMs: 30000
  });

  try {
    // Get week 1 games
    const games = await nfl.games.getGames(2024, 'REG', 1);

    console.log(`Found ${games.games?.length ?? 0} games\n`);

    for (const game of games.games ?? []) {
      const home = game.homeTeam;
      const away = game.awayTeam;

      console.log(`${away?.fullName} @ ${home?.fullName}`);
      console.log(`  Score: ${away?.score} - ${home?.score}`);
      console.log(`  Status: ${game.gameStatus}`);
      console.log();

      // Get box score for completed games
      if (game.gameStatus === 'FINAL' && game.id) {
        const box = await nfl.games.getBoxScore(game.id);
        console.log(`  Box Score:`, box);
        console.log();
      }
    }
  } catch (error) {
    if (error instanceof GriddyNFLError) {
      console.error(`Error: ${error.message}`);
    } else {
      throw error;
    }
  } finally {
    nfl.close();
  }
}

main();
```

## Differences from Python SDK

Key differences when migrating from Python:

| Feature | Python | TypeScript |
|---------|--------|------------|
| Methods | Sync + async (`get_games`, `get_games_async`) | Async only (`getGames`) |
| Property names | snake_case (`season_type`) | camelCase (`seasonType`) |
| Authentication | Token or browser-based | Token only |
| Context manager | `with` statement | Manual `close()` |
| Models | Pydantic with validation | Interfaces (no runtime validation) |

See [Python vs TypeScript Patterns](../guides/common-patterns/error-handling.md) for more details.

## Next Steps

- [Error Handling](../guides/common-patterns/error-handling.md) - Comprehensive error handling
- [Data Models](../guides/data-models/games.md) - Understanding response data
- [Choosing an SDK](choosing-sdk.md) - Compare Python and TypeScript options
