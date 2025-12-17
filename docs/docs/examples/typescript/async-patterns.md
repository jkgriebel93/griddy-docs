# Async Patterns

Advanced async/await patterns for the TypeScript SDK.

## Basic Async/Await

All TypeScript SDK methods are async and return Promises:

```typescript
import { GriddyNFL } from "griddy-sdk";

async function fetchGames() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const games = await nfl.games.getGames(2024, "REG", 1);
    return games;
  } finally {
    nfl.close();
  }
}
```

## Parallel Requests

### Using Promise.all

Fetch multiple resources simultaneously:

```typescript
async function fetchMultipleWeeks() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    // Fetch weeks 1-4 in parallel
    const [week1, week2, week3, week4] = await Promise.all([
      nfl.games.getGames(2024, "REG", 1),
      nfl.games.getGames(2024, "REG", 2),
      nfl.games.getGames(2024, "REG", 3),
      nfl.games.getGames(2024, "REG", 4),
    ]);

    console.log(`Week 1: ${week1.games?.length ?? 0} games`);
    console.log(`Week 2: ${week2.games?.length ?? 0} games`);
    console.log(`Week 3: ${week3.games?.length ?? 0} games`);
    console.log(`Week 4: ${week4.games?.length ?? 0} games`);
  } finally {
    nfl.close();
  }
}
```

### Using Promise.allSettled

Handle partial failures gracefully:

```typescript
async function fetchWithPartialFailures() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  const gameIds = ["game-1", "game-2", "game-3", "invalid-id"];

  try {
    const results = await Promise.allSettled(
      gameIds.map((id) => nfl.games.getBoxScore(id))
    );

    results.forEach((result, index) => {
      if (result.status === "fulfilled") {
        console.log(`Game ${gameIds[index]}: Success`);
      } else {
        console.log(`Game ${gameIds[index]}: Failed - ${result.reason}`);
      }
    });

    // Extract successful results
    const successfulResults = results
      .filter((r): r is PromiseFulfilledResult<any> => r.status === "fulfilled")
      .map((r) => r.value);

    return successfulResults;
  } finally {
    nfl.close();
  }
}
```

## Sequential Requests

When order matters or you need to avoid rate limits:

```typescript
async function fetchSequentially(gameIds: string[]) {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  const results: any[] = [];

  try {
    for (const gameId of gameIds) {
      const boxScore = await nfl.games.getBoxScore(gameId);
      results.push(boxScore);

      // Optional: Add delay between requests
      await delay(100);
    }

    return results;
  } finally {
    nfl.close();
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
```

## Batched Parallel Requests

Process items in batches to balance speed and rate limits:

```typescript
async function fetchInBatches<T>(
  items: string[],
  batchSize: number,
  fetcher: (id: string) => Promise<T>
): Promise<T[]> {
  const results: T[] = [];

  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const batchResults = await Promise.all(batch.map(fetcher));
    results.push(...batchResults);

    // Delay between batches
    if (i + batchSize < items.length) {
      await delay(200);
    }
  }

  return results;
}

// Usage
async function fetchAllBoxScores(gameIds: string[]) {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScores = await fetchInBatches(
      gameIds,
      5, // 5 requests per batch
      (id) => nfl.games.getBoxScore(id)
    );

    return boxScores;
  } finally {
    nfl.close();
  }
}
```

## Error Handling Patterns

### Try-Catch with Specific Errors

```typescript
async function fetchWithErrorHandling() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const games = await nfl.games.getGames(2024, "REG", 1);
    return games;
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.includes("401")) {
        console.error("Authentication failed - token may be expired");
        throw new Error("AUTH_EXPIRED");
      }
      if (error.message.includes("404")) {
        console.error("Resource not found");
        return null;
      }
      if (error.message.includes("429")) {
        console.error("Rate limited - waiting before retry");
        await delay(5000);
        return nfl.games.getGames(2024, "REG", 1);
      }
    }
    throw error;
  } finally {
    nfl.close();
  }
}
```

### Retry Pattern

```typescript
async function fetchWithRetry<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  delayMs: number = 1000
): Promise<T> {
  let lastError: Error | undefined;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      console.log(`Attempt ${attempt} failed: ${lastError.message}`);

      if (attempt < maxRetries) {
        const backoffDelay = delayMs * Math.pow(2, attempt - 1);
        console.log(`Retrying in ${backoffDelay}ms...`);
        await delay(backoffDelay);
      }
    }
  }

  throw lastError;
}

// Usage
async function reliableFetch() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const games = await fetchWithRetry(
      () => nfl.games.getGames(2024, "REG", 1),
      3,
      1000
    );
    return games;
  } finally {
    nfl.close();
  }
}
```

## Timeout Pattern

```typescript
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  const timeout = new Promise<never>((_, reject) => {
    setTimeout(() => reject(new Error("Request timed out")), ms);
  });

  return Promise.race([promise, timeout]);
}

// Usage
async function fetchWithTimeout() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const games = await withTimeout(
      nfl.games.getGames(2024, "REG", 1),
      10000 // 10 second timeout
    );
    return games;
  } finally {
    nfl.close();
  }
}
```

## Caching Pattern

```typescript
class CachedNFLClient {
  private nfl: GriddyNFL;
  private cache: Map<string, { data: any; expiry: number }> = new Map();
  private ttlMs: number;

  constructor(token: string, ttlMs: number = 60000) {
    this.nfl = new GriddyNFL({
      nflAuth: { accessToken: token },
    });
    this.ttlMs = ttlMs;
  }

  private getCacheKey(...args: any[]): string {
    return JSON.stringify(args);
  }

  async getGames(
    season: number,
    seasonType: string,
    week: number
  ): Promise<any> {
    const key = this.getCacheKey("games", season, seasonType, week);
    const cached = this.cache.get(key);

    if (cached && cached.expiry > Date.now()) {
      console.log("Cache hit");
      return cached.data;
    }

    console.log("Cache miss - fetching from API");
    const data = await this.nfl.games.getGames(
      season,
      seasonType as any,
      week
    );

    this.cache.set(key, {
      data,
      expiry: Date.now() + this.ttlMs,
    });

    return data;
  }

  close(): void {
    this.nfl.close();
  }
}

// Usage
async function useCachedClient() {
  const client = new CachedNFLClient(process.env.NFL_TOKEN!, 300000);

  try {
    // First call hits the API
    const games1 = await client.getGames(2024, "REG", 1);

    // Second call uses cache
    const games2 = await client.getGames(2024, "REG", 1);
  } finally {
    client.close();
  }
}
```

## Streaming-Like Processing

Process data as it arrives:

```typescript
async function* fetchGamesGenerator(
  nfl: GriddyNFL,
  season: number,
  weeks: number[]
) {
  for (const week of weeks) {
    const games = await nfl.games.getGames(season, "REG", week);
    for (const game of games.games ?? []) {
      yield { week, game };
    }
  }
}

// Usage
async function processGamesAsStream() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const generator = fetchGamesGenerator(nfl, 2024, [1, 2, 3, 4, 5]);

    for await (const { week, game } of generator) {
      console.log(`Week ${week}: ${game.homeTeam?.nickName} vs ${game.awayTeam?.nickName}`);
      // Process each game as it becomes available
    }
  } finally {
    nfl.close();
  }
}
```

## Next Steps

- [Basic Usage](basic-usage.md) - Fundamental SDK patterns
- [Testing Strategies](testing-strategies.md) - Testing async code
