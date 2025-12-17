# Fetch Player Stats

Examples for extracting and working with player statistics from game data.

!!! note "TypeScript SDK Coverage"
    The TypeScript SDK currently focuses on the Games endpoint. Player stats are available through box scores and play-by-play data. Advanced stats endpoints (passing, rushing, receiving) are planned for future releases.

## Getting Player Stats from Box Scores

```typescript
import { GriddyNFL } from "griddy-sdk";

interface PlayerStats {
  playerId: string;
  name: string;
  team: string;
  position: string;
  stats: Record<string, number>;
}

async function getPlayerStatsFromGame(gameId: string): Promise<PlayerStats[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScore = await nfl.games.getBoxScore(gameId);
    const players: PlayerStats[] = [];

    // Extract player stats from box score
    const playerStats = boxScore.playerStats ?? [];

    for (const stat of playerStats) {
      players.push({
        playerId: (stat as any).playerId ?? "",
        name: (stat as any).playerName ?? "Unknown",
        team: (stat as any).team ?? "",
        position: (stat as any).position ?? "",
        stats: (stat as any).stats ?? {},
      });
    }

    return players;
  } finally {
    nfl.close();
  }
}
```

## Extracting Passing Stats

```typescript
interface PassingStats {
  playerId: string;
  name: string;
  team: string;
  completions: number;
  attempts: number;
  yards: number;
  touchdowns: number;
  interceptions: number;
  rating: number;
}

async function getPassingStats(gameId: string): Promise<PassingStats[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScore = await nfl.games.getBoxScore(gameId);
    const passingStats: PassingStats[] = [];

    // Navigate to passing stats in box score structure
    const homeTeam = boxScore.homeTeam as Record<string, any>;
    const awayTeam = boxScore.awayTeam as Record<string, any>;

    const extractPassing = (teamData: Record<string, any>, teamName: string) => {
      const passing = teamData?.passing ?? [];
      for (const player of passing) {
        passingStats.push({
          playerId: player.playerId ?? "",
          name: player.name ?? "Unknown",
          team: teamName,
          completions: player.completions ?? 0,
          attempts: player.attempts ?? 0,
          yards: player.yards ?? 0,
          touchdowns: player.touchdowns ?? 0,
          interceptions: player.interceptions ?? 0,
          rating: player.rating ?? 0,
        });
      }
    };

    extractPassing(homeTeam, homeTeam?.name ?? "Home");
    extractPassing(awayTeam, awayTeam?.name ?? "Away");

    return passingStats;
  } finally {
    nfl.close();
  }
}
```

## Extracting Rushing Stats

```typescript
interface RushingStats {
  playerId: string;
  name: string;
  team: string;
  carries: number;
  yards: number;
  touchdowns: number;
  yardsPerCarry: number;
  longest: number;
}

async function getRushingStats(gameId: string): Promise<RushingStats[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScore = await nfl.games.getBoxScore(gameId);
    const rushingStats: RushingStats[] = [];

    const extractRushing = (teamData: Record<string, any>, teamName: string) => {
      const rushing = (teamData as any)?.rushing ?? [];
      for (const player of rushing) {
        rushingStats.push({
          playerId: player.playerId ?? "",
          name: player.name ?? "Unknown",
          team: teamName,
          carries: player.carries ?? 0,
          yards: player.yards ?? 0,
          touchdowns: player.touchdowns ?? 0,
          yardsPerCarry: player.yardsPerCarry ?? 0,
          longest: player.longest ?? 0,
        });
      }
    };

    extractRushing(boxScore.homeTeam ?? {}, "Home");
    extractRushing(boxScore.awayTeam ?? {}, "Away");

    return rushingStats;
  } finally {
    nfl.close();
  }
}
```

## Extracting Receiving Stats

```typescript
interface ReceivingStats {
  playerId: string;
  name: string;
  team: string;
  receptions: number;
  targets: number;
  yards: number;
  touchdowns: number;
  yardsPerReception: number;
  longest: number;
}

async function getReceivingStats(gameId: string): Promise<ReceivingStats[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScore = await nfl.games.getBoxScore(gameId);
    const receivingStats: ReceivingStats[] = [];

    const extractReceiving = (teamData: Record<string, any>, teamName: string) => {
      const receiving = (teamData as any)?.receiving ?? [];
      for (const player of receiving) {
        receivingStats.push({
          playerId: player.playerId ?? "",
          name: player.name ?? "Unknown",
          team: teamName,
          receptions: player.receptions ?? 0,
          targets: player.targets ?? 0,
          yards: player.yards ?? 0,
          touchdowns: player.touchdowns ?? 0,
          yardsPerReception: player.yardsPerReception ?? 0,
          longest: player.longest ?? 0,
        });
      }
    };

    extractReceiving(boxScore.homeTeam ?? {}, "Home");
    extractReceiving(boxScore.awayTeam ?? {}, "Away");

    return receivingStats;
  } finally {
    nfl.close();
  }
}
```

## Aggregating Stats Across Multiple Games

```typescript
interface AggregatedPlayerStats {
  playerId: string;
  name: string;
  gamesPlayed: number;
  totalYards: number;
  totalTouchdowns: number;
  averageYardsPerGame: number;
}

async function aggregatePlayerStats(
  gameIds: string[],
  statType: "passing" | "rushing" | "receiving"
): Promise<Map<string, AggregatedPlayerStats>> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  const playerMap = new Map<string, AggregatedPlayerStats>();

  try {
    for (const gameId of gameIds) {
      const boxScore = await nfl.games.getBoxScore(gameId);

      const processTeam = (teamData: Record<string, any>) => {
        const stats = (teamData as any)?.[statType] ?? [];

        for (const player of stats) {
          const playerId = player.playerId ?? player.name;
          const existing = playerMap.get(playerId);

          if (existing) {
            existing.gamesPlayed += 1;
            existing.totalYards += player.yards ?? 0;
            existing.totalTouchdowns += player.touchdowns ?? 0;
            existing.averageYardsPerGame =
              existing.totalYards / existing.gamesPlayed;
          } else {
            playerMap.set(playerId, {
              playerId,
              name: player.name ?? "Unknown",
              gamesPlayed: 1,
              totalYards: player.yards ?? 0,
              totalTouchdowns: player.touchdowns ?? 0,
              averageYardsPerGame: player.yards ?? 0,
            });
          }
        }
      };

      processTeam(boxScore.homeTeam ?? {});
      processTeam(boxScore.awayTeam ?? {});
    }

    return playerMap;
  } finally {
    nfl.close();
  }
}

// Usage
async function getSeasonLeaders() {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    // Get all games for first 4 weeks
    const allGameIds: string[] = [];

    for (let week = 1; week <= 4; week++) {
      const games = await nfl.games.getGames(2024, "REG", week);
      for (const game of games.games ?? []) {
        if (game.gameId) {
          allGameIds.push(game.gameId);
        }
      }
    }

    nfl.close();

    // Aggregate rushing stats
    const rushingLeaders = await aggregatePlayerStats(allGameIds, "rushing");

    // Sort by total yards
    const sortedLeaders = Array.from(rushingLeaders.values()).sort(
      (a, b) => b.totalYards - a.totalYards
    );

    console.log("Top 10 Rushing Leaders:");
    sortedLeaders.slice(0, 10).forEach((player, index) => {
      console.log(
        `${index + 1}. ${player.name}: ${player.totalYards} yards, ${player.totalTouchdowns} TDs`
      );
    });
  } finally {
    // Client already closed above
  }
}
```

## Player Stats from Play-by-Play

Get detailed play-level statistics:

```typescript
interface PlayLevelStats {
  playerId: string;
  name: string;
  plays: Array<{
    playId: string;
    type: string;
    yards: number;
    quarter: number;
  }>;
}

async function getPlayLevelStats(gameId: string): Promise<PlayLevelStats[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const pbp = await nfl.games.getPlayByPlay(gameId);
    const playerPlays = new Map<string, PlayLevelStats>();

    for (const play of pbp.plays ?? []) {
      const playData = play as Record<string, any>;
      const playerId = playData.primaryPlayerId;
      const playerName = playData.primaryPlayerName;

      if (!playerId) continue;

      let playerStats = playerPlays.get(playerId);
      if (!playerStats) {
        playerStats = {
          playerId,
          name: playerName ?? "Unknown",
          plays: [],
        };
        playerPlays.set(playerId, playerStats);
      }

      playerStats.plays.push({
        playId: playData.playId ?? "",
        type: playData.playType ?? "unknown",
        yards: playData.yards ?? 0,
        quarter: playData.quarter ?? 0,
      });
    }

    return Array.from(playerPlays.values());
  } finally {
    nfl.close();
  }
}
```

## Complete Example: Weekly Player Report

```typescript
import { GriddyNFL } from "griddy-sdk";

interface WeeklyPlayerReport {
  playerId: string;
  name: string;
  team: string;
  passing?: {
    yards: number;
    touchdowns: number;
    interceptions: number;
  };
  rushing?: {
    yards: number;
    touchdowns: number;
  };
  receiving?: {
    yards: number;
    touchdowns: number;
    receptions: number;
  };
}

async function generateWeeklyReport(
  season: number,
  week: number
): Promise<WeeklyPlayerReport[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  const reports: WeeklyPlayerReport[] = [];

  try {
    const games = await nfl.games.getGames(season, "REG", week);

    for (const game of games.games ?? []) {
      if (!game.gameId || game.gameStatus !== "FINAL") continue;

      const boxScore = await nfl.games.getBoxScore(game.gameId);

      const processTeam = (teamData: Record<string, any>, teamName: string) => {
        // Process passing
        for (const player of (teamData as any)?.passing ?? []) {
          reports.push({
            playerId: player.playerId,
            name: player.name,
            team: teamName,
            passing: {
              yards: player.yards ?? 0,
              touchdowns: player.touchdowns ?? 0,
              interceptions: player.interceptions ?? 0,
            },
          });
        }

        // Process rushing
        for (const player of (teamData as any)?.rushing ?? []) {
          reports.push({
            playerId: player.playerId,
            name: player.name,
            team: teamName,
            rushing: {
              yards: player.yards ?? 0,
              touchdowns: player.touchdowns ?? 0,
            },
          });
        }

        // Process receiving
        for (const player of (teamData as any)?.receiving ?? []) {
          reports.push({
            playerId: player.playerId,
            name: player.name,
            team: teamName,
            receiving: {
              yards: player.yards ?? 0,
              touchdowns: player.touchdowns ?? 0,
              receptions: player.receptions ?? 0,
            },
          });
        }
      };

      processTeam(
        boxScore.homeTeam ?? {},
        (game.homeTeam as any)?.nickName ?? "Home"
      );
      processTeam(
        boxScore.awayTeam ?? {},
        (game.awayTeam as any)?.nickName ?? "Away"
      );
    }

    return reports;
  } finally {
    nfl.close();
  }
}

// Usage
async function main() {
  const report = await generateWeeklyReport(2024, 1);

  console.log("Week 1 Player Report");
  console.log("====================\n");

  // Top passers
  const passers = report
    .filter((r) => r.passing)
    .sort((a, b) => (b.passing?.yards ?? 0) - (a.passing?.yards ?? 0))
    .slice(0, 5);

  console.log("Top 5 Passers:");
  passers.forEach((p) => {
    console.log(`  ${p.name} (${p.team}): ${p.passing?.yards} yards`);
  });

  // Top rushers
  const rushers = report
    .filter((r) => r.rushing)
    .sort((a, b) => (b.rushing?.yards ?? 0) - (a.rushing?.yards ?? 0))
    .slice(0, 5);

  console.log("\nTop 5 Rushers:");
  rushers.forEach((p) => {
    console.log(`  ${p.name} (${p.team}): ${p.rushing?.yards} yards`);
  });
}

main();
```

## Next Steps

- [Fantasy Integration](fantasy-integration.md) - Using stats for fantasy football
- [Game Predictions](game-predictions.md) - Analyzing game data
- [Basic Usage](basic-usage.md) - SDK fundamentals
