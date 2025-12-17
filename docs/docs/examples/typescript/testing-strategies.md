# Testing Strategies

Best practices and patterns for testing TypeScript applications using Griddy.

## Test Setup with Vitest

### Basic Configuration

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    setupFiles: ["./tests/setup.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
    },
  },
});
```

### Setup File

```typescript
// tests/setup.ts
import { beforeAll, afterAll, vi } from "vitest";

// Mock environment variables for tests
beforeAll(() => {
  process.env.NFL_TOKEN = "test-token";
});

afterAll(() => {
  vi.restoreAllMocks();
});
```

## Mocking the SDK

### Create a Mock Factory

```typescript
// tests/mocks/griddy.ts
import { vi } from "vitest";

export interface MockGames {
  getGames: ReturnType<typeof vi.fn>;
  getBoxScore: ReturnType<typeof vi.fn>;
  getPlayByPlay: ReturnType<typeof vi.fn>;
  getLiveGameStats: ReturnType<typeof vi.fn>;
  getWeeklyGameDetails: ReturnType<typeof vi.fn>;
}

export interface MockGriddyNFL {
  games: MockGames;
  close: ReturnType<typeof vi.fn>;
}

export function createMockGriddyNFL(): MockGriddyNFL {
  return {
    games: {
      getGames: vi.fn(),
      getBoxScore: vi.fn(),
      getPlayByPlay: vi.fn(),
      getLiveGameStats: vi.fn(),
      getWeeklyGameDetails: vi.fn(),
    },
    close: vi.fn(),
  };
}

// Mock the module
export function mockGriddyModule(mockNFL: MockGriddyNFL) {
  vi.mock("griddy-sdk", () => ({
    GriddyNFL: vi.fn().mockImplementation(() => mockNFL),
  }));
}
```

### Sample Test Data

```typescript
// tests/fixtures/games.ts
export const mockGamesResponse = {
  games: [
    {
      gameId: "game-001",
      gameStatus: "FINAL",
      homeTeam: {
        abbreviation: "KC",
        nickName: "Chiefs",
        score: 27,
      },
      awayTeam: {
        abbreviation: "DET",
        nickName: "Lions",
        score: 21,
      },
      gameTime: "2024-09-08T18:00:00Z",
    },
    {
      gameId: "game-002",
      gameStatus: "FINAL",
      homeTeam: {
        abbreviation: "SF",
        nickName: "49ers",
        score: 32,
      },
      awayTeam: {
        abbreviation: "NYJ",
        nickName: "Jets",
        score: 19,
      },
      gameTime: "2024-09-08T16:25:00Z",
    },
  ],
};

export const mockBoxScoreResponse = {
  gameId: "game-001",
  homeTeam: {
    name: "Chiefs",
    passing: [
      {
        playerId: "qb-001",
        name: "Patrick Mahomes",
        yards: 320,
        touchdowns: 3,
        interceptions: 0,
      },
    ],
    rushing: [
      {
        playerId: "rb-001",
        name: "Isiah Pacheco",
        yards: 78,
        touchdowns: 1,
        carries: 15,
      },
    ],
    receiving: [
      {
        playerId: "wr-001",
        name: "Travis Kelce",
        receptions: 8,
        yards: 95,
        touchdowns: 1,
      },
    ],
  },
  awayTeam: {
    name: "Lions",
    passing: [
      {
        playerId: "qb-002",
        name: "Jared Goff",
        yards: 275,
        touchdowns: 2,
        interceptions: 1,
      },
    ],
  },
};
```

## Unit Testing

### Testing a Service Layer

```typescript
// src/services/gameService.ts
import { GriddyNFL } from "griddy-sdk";

export class GameService {
  private nfl: GriddyNFL;

  constructor(token: string) {
    this.nfl = new GriddyNFL({
      nflAuth: { accessToken: token },
    });
  }

  async getCompletedGames(season: number, week: number) {
    const response = await this.nfl.games.getGames(season, "REG", week);
    return (response.games ?? []).filter(
      (game) => (game as any).gameStatus === "FINAL"
    );
  }

  async getGameScore(gameId: string) {
    const boxScore = await this.nfl.games.getBoxScore(gameId);
    return {
      home: (boxScore.homeTeam as any)?.score ?? 0,
      away: (boxScore.awayTeam as any)?.score ?? 0,
    };
  }

  close() {
    this.nfl.close();
  }
}
```

```typescript
// tests/services/gameService.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { GameService } from "../../src/services/gameService";
import { createMockGriddyNFL } from "../mocks/griddy";
import { mockGamesResponse, mockBoxScoreResponse } from "../fixtures/games";

vi.mock("griddy-sdk", () => ({
  GriddyNFL: vi.fn(),
}));

describe("GameService", () => {
  let service: GameService;
  let mockNFL: ReturnType<typeof createMockGriddyNFL>;

  beforeEach(async () => {
    mockNFL = createMockGriddyNFL();
    const { GriddyNFL } = await import("griddy-sdk");
    (GriddyNFL as any).mockImplementation(() => mockNFL);
    service = new GameService("test-token");
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe("getCompletedGames", () => {
    it("should return only completed games", async () => {
      mockNFL.games.getGames.mockResolvedValue({
        games: [
          { gameId: "1", gameStatus: "FINAL" },
          { gameId: "2", gameStatus: "IN_PROGRESS" },
          { gameId: "3", gameStatus: "FINAL" },
        ],
      });

      const games = await service.getCompletedGames(2024, 1);

      expect(games).toHaveLength(2);
      expect(games.every((g: any) => g.gameStatus === "FINAL")).toBe(true);
    });

    it("should call getGames with correct parameters", async () => {
      mockNFL.games.getGames.mockResolvedValue({ games: [] });

      await service.getCompletedGames(2024, 5);

      expect(mockNFL.games.getGames).toHaveBeenCalledWith(2024, "REG", 5);
    });

    it("should return empty array when no games", async () => {
      mockNFL.games.getGames.mockResolvedValue({ games: [] });

      const games = await service.getCompletedGames(2024, 1);

      expect(games).toHaveLength(0);
    });
  });

  describe("getGameScore", () => {
    it("should return home and away scores", async () => {
      mockNFL.games.getBoxScore.mockResolvedValue({
        homeTeam: { score: 27 },
        awayTeam: { score: 21 },
      });

      const score = await service.getGameScore("game-001");

      expect(score).toEqual({ home: 27, away: 21 });
    });

    it("should handle missing scores", async () => {
      mockNFL.games.getBoxScore.mockResolvedValue({
        homeTeam: {},
        awayTeam: {},
      });

      const score = await service.getGameScore("game-001");

      expect(score).toEqual({ home: 0, away: 0 });
    });
  });
});
```

## Integration Testing

### Testing with Real API Calls

```typescript
// tests/integration/games.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { GriddyNFL } from "griddy-sdk";

describe("Games Integration", () => {
  let nfl: GriddyNFL;

  beforeAll(() => {
    const token = process.env.NFL_TOKEN;
    if (!token) {
      throw new Error("NFL_TOKEN required for integration tests");
    }
    nfl = new GriddyNFL({ nflAuth: { accessToken: token } });
  });

  afterAll(() => {
    nfl.close();
  });

  it("should fetch games for a season week", async () => {
    const games = await nfl.games.getGames(2023, "REG", 1);

    expect(games.games).toBeDefined();
    expect(Array.isArray(games.games)).toBe(true);
    expect(games.games!.length).toBeGreaterThan(0);
  });

  it("should fetch box score for a completed game", async () => {
    // First get a completed game
    const games = await nfl.games.getGames(2023, "REG", 1);
    const completedGame = games.games?.find(
      (g) => (g as any).gameStatus === "FINAL"
    );

    if (!completedGame) {
      console.log("No completed games found, skipping");
      return;
    }

    const boxScore = await nfl.games.getBoxScore(completedGame.gameId!);

    expect(boxScore).toBeDefined();
    expect(boxScore.homeTeam).toBeDefined();
    expect(boxScore.awayTeam).toBeDefined();
  });
});
```

### Test Environment Configuration

```typescript
// tests/integration/setup.ts
export function skipIfNoToken() {
  if (!process.env.NFL_TOKEN) {
    console.warn("Skipping integration tests: NFL_TOKEN not set");
    return true;
  }
  return false;
}

// Usage in tests
describe("Integration Tests", () => {
  it("should run with real API", async () => {
    if (skipIfNoToken()) return;
    // ... test code
  });
});
```

## Testing Error Handling

```typescript
// tests/error-handling.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { createMockGriddyNFL } from "./mocks/griddy";

describe("Error Handling", () => {
  let mockNFL: ReturnType<typeof createMockGriddyNFL>;

  beforeEach(async () => {
    mockNFL = createMockGriddyNFL();
    vi.mock("griddy-sdk", () => ({
      GriddyNFL: vi.fn().mockImplementation(() => mockNFL),
    }));
  });

  it("should handle API errors gracefully", async () => {
    mockNFL.games.getGames.mockRejectedValue(new Error("API Error: 500"));

    const fetchGames = async () => {
      try {
        return await mockNFL.games.getGames(2024, "REG", 1);
      } catch (error) {
        return { error: (error as Error).message, games: [] };
      }
    };

    const result = await fetchGames();
    expect(result).toEqual({ error: "API Error: 500", games: [] });
  });

  it("should handle 401 authentication errors", async () => {
    mockNFL.games.getGames.mockRejectedValue(new Error("401 Unauthorized"));

    await expect(mockNFL.games.getGames(2024, "REG", 1)).rejects.toThrow(
      "401 Unauthorized"
    );
  });

  it("should handle 404 not found errors", async () => {
    mockNFL.games.getBoxScore.mockRejectedValue(new Error("404 Not Found"));

    await expect(mockNFL.games.getBoxScore("invalid-id")).rejects.toThrow(
      "404 Not Found"
    );
  });

  it("should handle rate limiting (429)", async () => {
    let callCount = 0;
    mockNFL.games.getGames.mockImplementation(async () => {
      callCount++;
      if (callCount < 3) {
        throw new Error("429 Rate Limited");
      }
      return { games: [] };
    });

    // Retry logic
    const fetchWithRetry = async (maxRetries = 3) => {
      for (let i = 0; i < maxRetries; i++) {
        try {
          return await mockNFL.games.getGames(2024, "REG", 1);
        } catch (error) {
          if (!(error as Error).message.includes("429") || i === maxRetries - 1) {
            throw error;
          }
          await new Promise((r) => setTimeout(r, 100));
        }
      }
    };

    const result = await fetchWithRetry();
    expect(result).toEqual({ games: [] });
    expect(callCount).toBe(3);
  });
});
```

## Testing Async Patterns

```typescript
// tests/async-patterns.test.ts
import { describe, it, expect, vi } from "vitest";
import { createMockGriddyNFL } from "./mocks/griddy";

describe("Async Patterns", () => {
  it("should handle parallel requests with Promise.all", async () => {
    const mockNFL = createMockGriddyNFL();

    mockNFL.games.getGames.mockImplementation(async (_, __, week) => ({
      games: [{ gameId: `game-week-${week}` }],
    }));

    const results = await Promise.all([
      mockNFL.games.getGames(2024, "REG", 1),
      mockNFL.games.getGames(2024, "REG", 2),
      mockNFL.games.getGames(2024, "REG", 3),
    ]);

    expect(results).toHaveLength(3);
    expect(results[0].games?.[0].gameId).toBe("game-week-1");
    expect(results[1].games?.[0].gameId).toBe("game-week-2");
    expect(results[2].games?.[0].gameId).toBe("game-week-3");
  });

  it("should handle Promise.allSettled for partial failures", async () => {
    const mockNFL = createMockGriddyNFL();

    mockNFL.games.getBoxScore
      .mockResolvedValueOnce({ gameId: "1" })
      .mockRejectedValueOnce(new Error("Not found"))
      .mockResolvedValueOnce({ gameId: "3" });

    const results = await Promise.allSettled([
      mockNFL.games.getBoxScore("game-1"),
      mockNFL.games.getBoxScore("game-2"),
      mockNFL.games.getBoxScore("game-3"),
    ]);

    expect(results[0].status).toBe("fulfilled");
    expect(results[1].status).toBe("rejected");
    expect(results[2].status).toBe("fulfilled");
  });
});
```

## Snapshot Testing

```typescript
// tests/snapshot.test.ts
import { describe, it, expect, vi } from "vitest";
import { createMockGriddyNFL } from "./mocks/griddy";
import { mockGamesResponse } from "./fixtures/games";

describe("Response Snapshots", () => {
  it("should match games response structure", async () => {
    const mockNFL = createMockGriddyNFL();
    mockNFL.games.getGames.mockResolvedValue(mockGamesResponse);

    const result = await mockNFL.games.getGames(2024, "REG", 1);

    expect(result).toMatchSnapshot();
  });

  it("should match transformed data structure", async () => {
    const mockNFL = createMockGriddyNFL();
    mockNFL.games.getGames.mockResolvedValue(mockGamesResponse);

    const result = await mockNFL.games.getGames(2024, "REG", 1);
    const transformed = result.games?.map((g: any) => ({
      id: g.gameId,
      matchup: `${g.awayTeam.nickName} @ ${g.homeTeam.nickName}`,
      score: `${g.awayTeam.score}-${g.homeTeam.score}`,
    }));

    expect(transformed).toMatchSnapshot();
  });
});
```

## Test Coverage Goals

```typescript
// vitest.config.ts - Coverage thresholds
export default defineConfig({
  test: {
    coverage: {
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 75,
        statements: 80,
      },
    },
  },
});
```

## Running Tests

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- tests/services/gameService.test.ts

# Run integration tests only
npm test -- tests/integration/

# Watch mode
npm test -- --watch
```

## Next Steps

- [Basic Usage](basic-usage.md) - SDK fundamentals to test
- [Async Patterns](async-patterns.md) - Async code patterns
