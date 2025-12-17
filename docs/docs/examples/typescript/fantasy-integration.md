# Fantasy Integration

Examples for using Griddy to power fantasy football applications.

## Calculating Fantasy Points

### Standard Scoring

```typescript
import { GriddyNFL } from "griddy-sdk";

interface FantasyScoring {
  passingYards: number;      // Points per yard
  passingTD: number;         // Points per TD
  passingInt: number;        // Points per INT (negative)
  rushingYards: number;      // Points per yard
  rushingTD: number;         // Points per TD
  receivingYards: number;    // Points per yard
  receivingTD: number;       // Points per TD
  reception: number;         // Points per reception (PPR)
  fumble: number;            // Points per fumble (negative)
}

const STANDARD_SCORING: FantasyScoring = {
  passingYards: 0.04,    // 1 point per 25 yards
  passingTD: 4,
  passingInt: -2,
  rushingYards: 0.1,     // 1 point per 10 yards
  rushingTD: 6,
  receivingYards: 0.1,
  receivingTD: 6,
  reception: 0,          // No PPR
  fumble: -2,
};

const PPR_SCORING: FantasyScoring = {
  ...STANDARD_SCORING,
  reception: 1,          // Full PPR
};

const HALF_PPR_SCORING: FantasyScoring = {
  ...STANDARD_SCORING,
  reception: 0.5,        // Half PPR
};
```

### Calculate Fantasy Points

```typescript
interface PlayerFantasyStats {
  playerId: string;
  name: string;
  team: string;
  position: string;
  passingYards: number;
  passingTDs: number;
  interceptions: number;
  rushingYards: number;
  rushingTDs: number;
  receptions: number;
  receivingYards: number;
  receivingTDs: number;
  fumbles: number;
}

function calculateFantasyPoints(
  stats: PlayerFantasyStats,
  scoring: FantasyScoring
): number {
  return (
    stats.passingYards * scoring.passingYards +
    stats.passingTDs * scoring.passingTD +
    stats.interceptions * scoring.passingInt +
    stats.rushingYards * scoring.rushingYards +
    stats.rushingTDs * scoring.rushingTD +
    stats.receptions * scoring.reception +
    stats.receivingYards * scoring.receivingYards +
    stats.receivingTDs * scoring.receivingTD +
    stats.fumbles * scoring.fumble
  );
}
```

## Extracting Fantasy Stats from Games

```typescript
async function getFantasyStatsFromGame(
  gameId: string
): Promise<PlayerFantasyStats[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const boxScore = await nfl.games.getBoxScore(gameId);
    const fantasyStats: PlayerFantasyStats[] = [];

    const processTeam = (teamData: Record<string, any>, teamName: string) => {
      // Track players to combine stats
      const playerMap = new Map<string, PlayerFantasyStats>();

      const getOrCreate = (playerId: string, name: string, position: string) => {
        if (!playerMap.has(playerId)) {
          playerMap.set(playerId, {
            playerId,
            name,
            team: teamName,
            position,
            passingYards: 0,
            passingTDs: 0,
            interceptions: 0,
            rushingYards: 0,
            rushingTDs: 0,
            receptions: 0,
            receivingYards: 0,
            receivingTDs: 0,
            fumbles: 0,
          });
        }
        return playerMap.get(playerId)!;
      };

      // Process passing
      for (const player of (teamData as any)?.passing ?? []) {
        const stats = getOrCreate(player.playerId, player.name, "QB");
        stats.passingYards += player.yards ?? 0;
        stats.passingTDs += player.touchdowns ?? 0;
        stats.interceptions += player.interceptions ?? 0;
      }

      // Process rushing
      for (const player of (teamData as any)?.rushing ?? []) {
        const stats = getOrCreate(player.playerId, player.name, player.position ?? "RB");
        stats.rushingYards += player.yards ?? 0;
        stats.rushingTDs += player.touchdowns ?? 0;
      }

      // Process receiving
      for (const player of (teamData as any)?.receiving ?? []) {
        const stats = getOrCreate(player.playerId, player.name, player.position ?? "WR");
        stats.receptions += player.receptions ?? 0;
        stats.receivingYards += player.yards ?? 0;
        stats.receivingTDs += player.touchdowns ?? 0;
      }

      // Process fumbles
      for (const player of (teamData as any)?.fumbles ?? []) {
        const stats = getOrCreate(player.playerId, player.name, player.position ?? "");
        stats.fumbles += player.lost ?? 0;
      }

      fantasyStats.push(...playerMap.values());
    };

    const homeTeamName = (boxScore.homeTeam as any)?.name ?? "Home";
    const awayTeamName = (boxScore.awayTeam as any)?.name ?? "Away";

    processTeam(boxScore.homeTeam ?? {}, homeTeamName);
    processTeam(boxScore.awayTeam ?? {}, awayTeamName);

    return fantasyStats;
  } finally {
    nfl.close();
  }
}
```

## Weekly Fantasy Leaderboard

```typescript
interface FantasyLeader {
  rank: number;
  playerId: string;
  name: string;
  team: string;
  position: string;
  points: number;
  stats: PlayerFantasyStats;
}

async function getWeeklyFantasyLeaders(
  season: number,
  week: number,
  scoring: FantasyScoring = PPR_SCORING,
  positions?: string[]
): Promise<FantasyLeader[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    const games = await nfl.games.getGames(season, "REG", week);
    const allStats: PlayerFantasyStats[] = [];

    // Collect stats from all games
    for (const game of games.games ?? []) {
      if (!game.gameId || game.gameStatus !== "FINAL") continue;

      const gameStats = await getFantasyStatsFromGame(game.gameId);
      allStats.push(...gameStats);
    }

    // Calculate fantasy points
    const leaders = allStats
      .filter((player) => !positions || positions.includes(player.position))
      .map((stats) => ({
        playerId: stats.playerId,
        name: stats.name,
        team: stats.team,
        position: stats.position,
        points: calculateFantasyPoints(stats, scoring),
        stats,
      }))
      .sort((a, b) => b.points - a.points)
      .map((player, index) => ({
        rank: index + 1,
        ...player,
      }));

    return leaders;
  } finally {
    nfl.close();
  }
}

// Usage
async function showWeeklyLeaders() {
  const leaders = await getWeeklyFantasyLeaders(2024, 1, PPR_SCORING);

  console.log("Week 1 Fantasy Leaders (PPR)\n");

  console.log("Top 10 Overall:");
  leaders.slice(0, 10).forEach((player) => {
    console.log(
      `  ${player.rank}. ${player.name} (${player.position}, ${player.team}): ${player.points.toFixed(1)} pts`
    );
  });

  console.log("\nTop 5 QBs:");
  leaders
    .filter((p) => p.position === "QB")
    .slice(0, 5)
    .forEach((player) => {
      console.log(`  ${player.name}: ${player.points.toFixed(1)} pts`);
    });

  console.log("\nTop 5 RBs:");
  leaders
    .filter((p) => p.position === "RB")
    .slice(0, 5)
    .forEach((player) => {
      console.log(`  ${player.name}: ${player.points.toFixed(1)} pts`);
    });

  console.log("\nTop 5 WRs:");
  leaders
    .filter((p) => p.position === "WR")
    .slice(0, 5)
    .forEach((player) => {
      console.log(`  ${player.name}: ${player.points.toFixed(1)} pts`);
    });
}
```

## Season-Long Fantasy Totals

```typescript
interface SeasonFantasyStats {
  playerId: string;
  name: string;
  team: string;
  position: string;
  gamesPlayed: number;
  totalPoints: number;
  averagePoints: number;
  weeklyScores: number[];
  bestWeek: number;
  worstWeek: number;
}

async function getSeasonFantasyTotals(
  season: number,
  throughWeek: number,
  scoring: FantasyScoring = PPR_SCORING
): Promise<SeasonFantasyStats[]> {
  const playerSeasonStats = new Map<string, SeasonFantasyStats>();

  for (let week = 1; week <= throughWeek; week++) {
    const leaders = await getWeeklyFantasyLeaders(season, week, scoring);

    for (const player of leaders) {
      let seasonStats = playerSeasonStats.get(player.playerId);

      if (!seasonStats) {
        seasonStats = {
          playerId: player.playerId,
          name: player.name,
          team: player.team,
          position: player.position,
          gamesPlayed: 0,
          totalPoints: 0,
          averagePoints: 0,
          weeklyScores: [],
          bestWeek: 0,
          worstWeek: Infinity,
        };
        playerSeasonStats.set(player.playerId, seasonStats);
      }

      seasonStats.gamesPlayed++;
      seasonStats.totalPoints += player.points;
      seasonStats.weeklyScores.push(player.points);
      seasonStats.bestWeek = Math.max(seasonStats.bestWeek, player.points);
      seasonStats.worstWeek = Math.min(seasonStats.worstWeek, player.points);
    }
  }

  // Calculate averages and fix worst week
  const results = Array.from(playerSeasonStats.values()).map((stats) => ({
    ...stats,
    averagePoints: stats.totalPoints / stats.gamesPlayed,
    worstWeek: stats.worstWeek === Infinity ? 0 : stats.worstWeek,
  }));

  return results.sort((a, b) => b.totalPoints - a.totalPoints);
}
```

## Matchup Analysis

```typescript
interface FantasyMatchup {
  team1: {
    name: string;
    players: Array<{ name: string; position: string; projectedPoints: number }>;
    totalProjected: number;
  };
  team2: {
    name: string;
    players: Array<{ name: string; position: string; projectedPoints: number }>;
    totalProjected: number;
  };
  projectedWinner: string;
  marginOfVictory: number;
}

async function analyzeFantasyMatchup(
  team1PlayerIds: string[],
  team2PlayerIds: string[],
  team1Name: string,
  team2Name: string,
  season: number,
  throughWeek: number
): Promise<FantasyMatchup> {
  const seasonStats = await getSeasonFantasyTotals(season, throughWeek);
  const statsMap = new Map(seasonStats.map((s) => [s.playerId, s]));

  const getTeamProjections = (playerIds: string[]) => {
    const players = playerIds.map((id) => {
      const stats = statsMap.get(id);
      return {
        name: stats?.name ?? "Unknown",
        position: stats?.position ?? "",
        projectedPoints: stats?.averagePoints ?? 0,
      };
    });

    return {
      players,
      totalProjected: players.reduce((sum, p) => sum + p.projectedPoints, 0),
    };
  };

  const team1 = { name: team1Name, ...getTeamProjections(team1PlayerIds) };
  const team2 = { name: team2Name, ...getTeamProjections(team2PlayerIds) };

  return {
    team1,
    team2,
    projectedWinner:
      team1.totalProjected > team2.totalProjected ? team1Name : team2Name,
    marginOfVictory: Math.abs(team1.totalProjected - team2.totalProjected),
  };
}
```

## Waiver Wire Suggestions

```typescript
interface WaiverSuggestion {
  playerId: string;
  name: string;
  team: string;
  position: string;
  reason: string;
  recentAverage: number;
  trendDirection: "up" | "down" | "stable";
  priority: number;
}

async function getWaiverSuggestions(
  season: number,
  currentWeek: number,
  rosterPlayerIds: string[],
  positions: string[] = ["QB", "RB", "WR", "TE"]
): Promise<WaiverSuggestion[]> {
  // Get last 3 weeks of data
  const startWeek = Math.max(1, currentWeek - 3);
  const weeklyStats: Map<string, number[]> = new Map();

  for (let week = startWeek; week < currentWeek; week++) {
    const leaders = await getWeeklyFantasyLeaders(season, week, PPR_SCORING, positions);

    for (const player of leaders) {
      if (!weeklyStats.has(player.playerId)) {
        weeklyStats.set(player.playerId, []);
      }
      weeklyStats.get(player.playerId)!.push(player.points);
    }
  }

  const suggestions: WaiverSuggestion[] = [];
  const seasonStats = await getSeasonFantasyTotals(season, currentWeek - 1);
  const statsMap = new Map(seasonStats.map((s) => [s.playerId, s]));

  for (const [playerId, scores] of weeklyStats) {
    // Skip players already on roster
    if (rosterPlayerIds.includes(playerId)) continue;

    const stats = statsMap.get(playerId);
    if (!stats || scores.length < 2) continue;

    // Calculate trend
    const recentAvg = scores.slice(-2).reduce((a, b) => a + b, 0) / 2;
    const olderAvg = scores.slice(0, -2).reduce((a, b) => a + b, 0) / Math.max(1, scores.length - 2);

    const trendDirection: "up" | "down" | "stable" =
      recentAvg > olderAvg * 1.2 ? "up" :
      recentAvg < olderAvg * 0.8 ? "down" : "stable";

    // Only suggest trending up players
    if (trendDirection !== "up") continue;

    suggestions.push({
      playerId,
      name: stats.name,
      team: stats.team,
      position: stats.position,
      reason: `Averaging ${recentAvg.toFixed(1)} pts last 2 weeks (up from ${olderAvg.toFixed(1)})`,
      recentAverage: recentAvg,
      trendDirection,
      priority: recentAvg - olderAvg, // Higher increase = higher priority
    });
  }

  return suggestions.sort((a, b) => b.priority - a.priority);
}
```

## Complete Fantasy Dashboard

```typescript
async function fantasyDashboard(
  season: number,
  week: number,
  myRosterIds: string[]
) {
  console.log(`Fantasy Dashboard - Week ${week}\n`);
  console.log("=".repeat(50) + "\n");

  // Weekly leaders
  const leaders = await getWeeklyFantasyLeaders(season, week - 1, PPR_SCORING);
  console.log("Last Week's Top Performers:");
  leaders.slice(0, 5).forEach((p) => {
    console.log(`  ${p.name} (${p.position}): ${p.points.toFixed(1)} pts`);
  });

  // My roster performance
  console.log("\nMy Roster Performance:");
  const myPlayers = leaders.filter((p) => myRosterIds.includes(p.playerId));
  const totalPoints = myPlayers.reduce((sum, p) => sum + p.points, 0);
  myPlayers.forEach((p) => {
    console.log(`  ${p.name} (${p.position}): ${p.points.toFixed(1)} pts`);
  });
  console.log(`  Total: ${totalPoints.toFixed(1)} pts`);

  // Waiver suggestions
  const suggestions = await getWaiverSuggestions(
    season,
    week,
    myRosterIds
  );
  console.log("\nWaiver Wire Suggestions:");
  suggestions.slice(0, 5).forEach((s) => {
    console.log(`  ${s.name} (${s.position}, ${s.team})`);
    console.log(`    ${s.reason}`);
  });
}

// Usage
fantasyDashboard(2024, 5, ["player-id-1", "player-id-2"]);
```

## Next Steps

- [Fetch Player Stats](fetch-player-stats.md) - Detailed player statistics
- [Game Predictions](game-predictions.md) - Game analysis for DFS
- [Testing Strategies](testing-strategies.md) - Testing your fantasy app
