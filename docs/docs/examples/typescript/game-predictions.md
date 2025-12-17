# Game Predictions

Examples for analyzing game data to support predictions and analysis.

## Collecting Historical Game Data

```typescript
import { GriddyNFL } from "griddy-sdk";

interface GameResult {
  gameId: string;
  season: number;
  week: number;
  homeTeam: string;
  awayTeam: string;
  homeScore: number;
  awayScore: number;
  winner: "home" | "away" | "tie";
  totalPoints: number;
  pointSpread: number;
}

async function collectHistoricalGames(
  season: number,
  weeks: number[]
): Promise<GameResult[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  const results: GameResult[] = [];

  try {
    for (const week of weeks) {
      const games = await nfl.games.getGames(season, "REG", week);

      for (const game of games.games ?? []) {
        const homeScore = (game.homeTeam as any)?.score ?? 0;
        const awayScore = (game.awayTeam as any)?.score ?? 0;

        if (game.gameStatus !== "FINAL") continue;

        results.push({
          gameId: game.gameId ?? "",
          season,
          week,
          homeTeam: (game.homeTeam as any)?.abbreviation ?? "",
          awayTeam: (game.awayTeam as any)?.abbreviation ?? "",
          homeScore,
          awayScore,
          winner: homeScore > awayScore ? "home" : awayScore > homeScore ? "away" : "tie",
          totalPoints: homeScore + awayScore,
          pointSpread: homeScore - awayScore,
        });
      }
    }

    return results;
  } finally {
    nfl.close();
  }
}
```

## Team Performance Analysis

```typescript
interface TeamStats {
  team: string;
  gamesPlayed: number;
  wins: number;
  losses: number;
  ties: number;
  pointsFor: number;
  pointsAgainst: number;
  averagePointsFor: number;
  averagePointsAgainst: number;
  homeRecord: { wins: number; losses: number };
  awayRecord: { wins: number; losses: number };
}

function analyzeTeamPerformance(games: GameResult[]): Map<string, TeamStats> {
  const teamStats = new Map<string, TeamStats>();

  const getOrCreate = (team: string): TeamStats => {
    if (!teamStats.has(team)) {
      teamStats.set(team, {
        team,
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
        ties: 0,
        pointsFor: 0,
        pointsAgainst: 0,
        averagePointsFor: 0,
        averagePointsAgainst: 0,
        homeRecord: { wins: 0, losses: 0 },
        awayRecord: { wins: 0, losses: 0 },
      });
    }
    return teamStats.get(team)!;
  };

  for (const game of games) {
    const home = getOrCreate(game.homeTeam);
    const away = getOrCreate(game.awayTeam);

    // Update home team
    home.gamesPlayed++;
    home.pointsFor += game.homeScore;
    home.pointsAgainst += game.awayScore;

    if (game.winner === "home") {
      home.wins++;
      home.homeRecord.wins++;
    } else if (game.winner === "away") {
      home.losses++;
      home.homeRecord.losses++;
    } else {
      home.ties++;
    }

    // Update away team
    away.gamesPlayed++;
    away.pointsFor += game.awayScore;
    away.pointsAgainst += game.homeScore;

    if (game.winner === "away") {
      away.wins++;
      away.awayRecord.wins++;
    } else if (game.winner === "home") {
      away.losses++;
      away.awayRecord.losses++;
    } else {
      away.ties++;
    }
  }

  // Calculate averages
  for (const stats of teamStats.values()) {
    if (stats.gamesPlayed > 0) {
      stats.averagePointsFor = stats.pointsFor / stats.gamesPlayed;
      stats.averagePointsAgainst = stats.pointsAgainst / stats.gamesPlayed;
    }
  }

  return teamStats;
}
```

## Simple Prediction Model

```typescript
interface Prediction {
  homeTeam: string;
  awayTeam: string;
  predictedWinner: string;
  confidence: number;
  predictedHomeScore: number;
  predictedAwayScore: number;
  predictedTotal: number;
  predictedSpread: number;
}

function predictGame(
  homeTeam: string,
  awayTeam: string,
  teamStats: Map<string, TeamStats>
): Prediction | null {
  const home = teamStats.get(homeTeam);
  const away = teamStats.get(awayTeam);

  if (!home || !away) {
    return null;
  }

  // Home field advantage factor
  const HOME_ADVANTAGE = 2.5;

  // Calculate expected points
  const homeOffense = home.averagePointsFor;
  const homeDefense = home.averagePointsAgainst;
  const awayOffense = away.averagePointsFor;
  const awayDefense = away.averagePointsAgainst;

  // Simple model: average of offense vs opposing defense
  const predictedHomeScore =
    (homeOffense + awayDefense) / 2 + HOME_ADVANTAGE;
  const predictedAwayScore =
    (awayOffense + homeDefense) / 2;

  const predictedSpread = predictedHomeScore - predictedAwayScore;

  // Calculate confidence based on sample size and consistency
  const minGames = Math.min(home.gamesPlayed, away.gamesPlayed);
  const baseConfidence = Math.min(minGames / 8, 1) * 0.5; // Max 50% from sample size

  // Add confidence from spread magnitude
  const spreadConfidence = Math.min(Math.abs(predictedSpread) / 10, 0.5);

  const confidence = baseConfidence + spreadConfidence;

  return {
    homeTeam,
    awayTeam,
    predictedWinner: predictedSpread > 0 ? homeTeam : awayTeam,
    confidence,
    predictedHomeScore: Math.round(predictedHomeScore),
    predictedAwayScore: Math.round(predictedAwayScore),
    predictedTotal: Math.round(predictedHomeScore + predictedAwayScore),
    predictedSpread: Math.round(predictedSpread * 10) / 10,
  };
}
```

## Head-to-Head Analysis

```typescript
interface HeadToHead {
  team1: string;
  team2: string;
  team1Wins: number;
  team2Wins: number;
  ties: number;
  recentGames: GameResult[];
  averageTotal: number;
  averageSpread: number;
}

function analyzeHeadToHead(
  team1: string,
  team2: string,
  games: GameResult[]
): HeadToHead {
  const matchups = games.filter(
    (g) =>
      (g.homeTeam === team1 && g.awayTeam === team2) ||
      (g.homeTeam === team2 && g.awayTeam === team1)
  );

  const result: HeadToHead = {
    team1,
    team2,
    team1Wins: 0,
    team2Wins: 0,
    ties: 0,
    recentGames: matchups.slice(-5), // Last 5 games
    averageTotal: 0,
    averageSpread: 0,
  };

  let totalPoints = 0;
  let totalSpread = 0;

  for (const game of matchups) {
    const team1IsHome = game.homeTeam === team1;
    const team1Score = team1IsHome ? game.homeScore : game.awayScore;
    const team2Score = team1IsHome ? game.awayScore : game.homeScore;

    if (team1Score > team2Score) {
      result.team1Wins++;
    } else if (team2Score > team1Score) {
      result.team2Wins++;
    } else {
      result.ties++;
    }

    totalPoints += game.totalPoints;
    totalSpread += team1Score - team2Score;
  }

  if (matchups.length > 0) {
    result.averageTotal = totalPoints / matchups.length;
    result.averageSpread = totalSpread / matchups.length;
  }

  return result;
}
```

## Trend Analysis

```typescript
interface TrendAnalysis {
  team: string;
  last3: { wins: number; losses: number; pointsPerGame: number };
  last5: { wins: number; losses: number; pointsPerGame: number };
  lastWeekResult: GameResult | null;
  trending: "up" | "down" | "stable";
}

function analyzeTrends(
  team: string,
  games: GameResult[]
): TrendAnalysis {
  // Filter games for this team and sort by week
  const teamGames = games
    .filter((g) => g.homeTeam === team || g.awayTeam === team)
    .sort((a, b) => a.week - b.week);

  const getRecord = (recentGames: GameResult[]) => {
    let wins = 0;
    let losses = 0;
    let totalPoints = 0;

    for (const game of recentGames) {
      const isHome = game.homeTeam === team;
      const teamScore = isHome ? game.homeScore : game.awayScore;
      const oppScore = isHome ? game.awayScore : game.homeScore;

      totalPoints += teamScore;

      if (teamScore > oppScore) wins++;
      else if (oppScore > teamScore) losses++;
    }

    return {
      wins,
      losses,
      pointsPerGame: recentGames.length > 0 ? totalPoints / recentGames.length : 0,
    };
  };

  const last3 = getRecord(teamGames.slice(-3));
  const last5 = getRecord(teamGames.slice(-5));
  const lastWeekResult = teamGames[teamGames.length - 1] ?? null;

  // Determine trend
  let trending: "up" | "down" | "stable" = "stable";
  if (last3.wins >= 2 && last5.wins >= 3) {
    trending = "up";
  } else if (last3.losses >= 2 && last5.losses >= 3) {
    trending = "down";
  }

  return {
    team,
    last3,
    last5,
    lastWeekResult,
    trending,
  };
}
```

## Complete Prediction System

```typescript
import { GriddyNFL } from "griddy-sdk";

interface GamePrediction {
  homeTeam: string;
  awayTeam: string;
  prediction: Prediction | null;
  homeTeamTrend: TrendAnalysis;
  awayTeamTrend: TrendAnalysis;
  headToHead: HeadToHead;
}

async function generateWeeklyPredictions(
  season: number,
  predictionWeek: number
): Promise<GamePrediction[]> {
  const nfl = new GriddyNFL({
    nflAuth: { accessToken: process.env.NFL_TOKEN! },
  });

  try {
    // Collect historical data (all completed weeks)
    const completedWeeks = Array.from(
      { length: predictionWeek - 1 },
      (_, i) => i + 1
    );
    const historicalGames = await collectHistoricalGames(season, completedWeeks);

    // Analyze team performance
    const teamStats = analyzeTeamPerformance(historicalGames);

    // Get upcoming games
    const upcomingGames = await nfl.games.getGames(season, "REG", predictionWeek);

    const predictions: GamePrediction[] = [];

    for (const game of upcomingGames.games ?? []) {
      const homeTeam = (game.homeTeam as any)?.abbreviation ?? "";
      const awayTeam = (game.awayTeam as any)?.abbreviation ?? "";

      predictions.push({
        homeTeam,
        awayTeam,
        prediction: predictGame(homeTeam, awayTeam, teamStats),
        homeTeamTrend: analyzeTrends(homeTeam, historicalGames),
        awayTeamTrend: analyzeTrends(awayTeam, historicalGames),
        headToHead: analyzeHeadToHead(homeTeam, awayTeam, historicalGames),
      });
    }

    return predictions;
  } finally {
    nfl.close();
  }
}

// Usage
async function main() {
  const predictions = await generateWeeklyPredictions(2024, 10);

  console.log("Week 10 Predictions\n");
  console.log("===================\n");

  for (const pred of predictions) {
    console.log(`${pred.awayTeam} @ ${pred.homeTeam}`);

    if (pred.prediction) {
      console.log(`  Predicted Winner: ${pred.prediction.predictedWinner}`);
      console.log(
        `  Predicted Score: ${pred.prediction.predictedAwayScore} - ${pred.prediction.predictedHomeScore}`
      );
      console.log(`  Spread: ${pred.prediction.predictedSpread > 0 ? "+" : ""}${pred.prediction.predictedSpread}`);
      console.log(`  Over/Under: ${pred.prediction.predictedTotal}`);
      console.log(`  Confidence: ${(pred.prediction.confidence * 100).toFixed(0)}%`);
    }

    console.log(`  ${pred.homeTeam} Trend: ${pred.homeTeamTrend.trending}`);
    console.log(`  ${pred.awayTeam} Trend: ${pred.awayTeamTrend.trending}`);
    console.log();
  }
}

main();
```

## Exporting Data for External Models

```typescript
interface ModelInput {
  gameId: string;
  features: {
    homeWinPct: number;
    awayWinPct: number;
    homeAvgPointsFor: number;
    homeAvgPointsAgainst: number;
    awayAvgPointsFor: number;
    awayAvgPointsAgainst: number;
    homeLastThreeWins: number;
    awayLastThreeWins: number;
    headToHeadWinPct: number;
  };
  label?: number; // 1 for home win, 0 for away win (if known)
}

async function prepareModelData(
  season: number,
  weeks: number[]
): Promise<ModelInput[]> {
  const games = await collectHistoricalGames(season, weeks);
  const teamStats = analyzeTeamPerformance(games);

  const modelInputs: ModelInput[] = [];

  for (const game of games) {
    const home = teamStats.get(game.homeTeam);
    const away = teamStats.get(game.awayTeam);
    const h2h = analyzeHeadToHead(game.homeTeam, game.awayTeam, games);
    const homeTrend = analyzeTrends(game.homeTeam, games);
    const awayTrend = analyzeTrends(game.awayTeam, games);

    if (!home || !away) continue;

    modelInputs.push({
      gameId: game.gameId,
      features: {
        homeWinPct: home.wins / home.gamesPlayed,
        awayWinPct: away.wins / away.gamesPlayed,
        homeAvgPointsFor: home.averagePointsFor,
        homeAvgPointsAgainst: home.averagePointsAgainst,
        awayAvgPointsFor: away.averagePointsFor,
        awayAvgPointsAgainst: away.averagePointsAgainst,
        homeLastThreeWins: homeTrend.last3.wins,
        awayLastThreeWins: awayTrend.last3.wins,
        headToHeadWinPct:
          h2h.team1Wins + h2h.team2Wins > 0
            ? h2h.team1Wins / (h2h.team1Wins + h2h.team2Wins)
            : 0.5,
      },
      label: game.winner === "home" ? 1 : 0,
    });
  }

  return modelInputs;
}
```

## Next Steps

- [Fetch Player Stats](fetch-player-stats.md) - Player-level analysis
- [Fantasy Integration](fantasy-integration.md) - Fantasy football applications
- [Async Patterns](async-patterns.md) - Efficient data fetching
