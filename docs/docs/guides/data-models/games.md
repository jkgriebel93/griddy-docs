# Games Data Model

This guide covers the game data structures returned by the Griddy SDK.

## Game Information

Games are the primary data entity for NFL schedules and scores.

### Basic Game Fields

| Field | Python | TypeScript | Type | Description |
|-------|--------|------------|------|-------------|
| ID | `id` | `id` | string | Unique game identifier (UUID) |
| Season | `season` | `season` | number | Season year |
| Season Type | `season_type` | `seasonType` | enum | PRE, REG, or POST |
| Week | `week` | `week` | number | Week number |
| Game Status | `game_status` | `gameStatus` | string | Current game status |
| Home Team | `home_team` | `homeTeam` | Team | Home team info |
| Away Team | `away_team` | `awayTeam` | Team | Away team info |
| Start Time | `start_time` | `startTime` | datetime | Scheduled start time |
| Venue | `venue` | `venue` | Venue | Stadium information |

## Getting Games

### By Week

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL

    nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

    games = nfl.games.get_games(
        season=2024,
        season_type="REG",  # PRE, REG, or POST
        week=1
    )

    for game in games.games:
        print(f"Game ID: {game.id}")
        print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")
        print(f"Status: {game.game_status}")
        print(f"Score: {game.away_team.score} - {game.home_team.score}")
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

    const games = await nfl.games.getGames(2024, 'REG', 1);

    games.games?.forEach(game => {
      console.log(`Game ID: ${game.id}`);
      console.log(`${game.awayTeam?.abbreviation} @ ${game.homeTeam?.abbreviation}`);
      console.log(`Status: ${game.gameStatus}`);
      console.log(`Score: ${game.awayTeam?.score} - ${game.homeTeam?.score}`);
    });
    ```

## Season Types

| Value | Description |
|-------|-------------|
| `PRE` | Preseason games |
| `REG` | Regular season games |
| `POST` | Postseason/playoff games |

```python
# Preseason games
preseason = nfl.games.get_games(season=2024, season_type="PRE", week=1)

# Regular season
regular = nfl.games.get_games(season=2024, season_type="REG", week=1)

# Playoffs
playoffs = nfl.games.get_games(season=2024, season_type="POST", week=1)
```

## Game Status

Common game status values:

| Status | Description |
|--------|-------------|
| `SCHEDULED` | Game not yet started |
| `IN_PROGRESS` | Game currently in progress |
| `HALFTIME` | At halftime |
| `FINAL` | Game completed |
| `FINAL_OVERTIME` | Game completed in overtime |
| `POSTPONED` | Game postponed |
| `CANCELLED` | Game cancelled |

```python
# Filter by status
live_games = [g for g in games.games if g.game_status == "IN_PROGRESS"]
completed = [g for g in games.games if g.game_status.startswith("FINAL")]
```

## Box Scores

Get detailed game statistics:

=== "Python"

    ```python
    box_score = nfl.games.get_box_score(game_id="game-uuid")

    print(f"Home Score: {box_score.home_team_score}")
    print(f"Away Score: {box_score.away_team_score}")

    # Team statistics
    print(f"Home Total Yards: {box_score.home_team_stats.total_yards}")
    print(f"Away Total Yards: {box_score.away_team_stats.total_yards}")

    # Scoring summary
    for score in box_score.scoring_summary:
        print(f"Q{score.quarter}: {score.description}")
    ```

=== "TypeScript"

    ```typescript
    const boxScore = await nfl.games.getBoxScore('game-uuid');

    console.log('Home Team:', boxScore.homeTeam);
    console.log('Away Team:', boxScore.awayTeam);
    console.log('Scoring Summary:', boxScore.scoringSummary);
    ```

## Play-by-Play

Get detailed play data:

=== "Python"

    ```python
    pbp = nfl.games.get_play_by_play(
        game_id="game-uuid",
        include_penalties=True,
        include_formations=False
    )

    for play in pbp.plays:
        print(f"Q{play.quarter} {play.clock}")
        print(f"  {play.down} & {play.yards_to_go} at {play.yard_line}")
        print(f"  {play.description}")
    ```

=== "TypeScript"

    ```typescript
    const pbp = await nfl.games.getPlayByPlay(
      'game-uuid',
      true,   // includePenalties
      false   // includeFormations
    );

    pbp.plays?.forEach(play => {
      console.log(`Q${play.quarter}: ${play.description}`);
    });
    ```

## Live Game Stats

Get real-time statistics for games in progress:

=== "Python"

    ```python
    live_stats = nfl.games.get_live_game_stats(
        season=2024,
        season_type="REG",
        week=1
    )

    for game_stats in live_stats:
        print(f"Game: {game_stats.game_id}")
        print(f"Status: {game_stats.game_status}")
    ```

=== "TypeScript"

    ```typescript
    const liveStats = await nfl.games.getLiveGameStats(2024, 'REG', 1);

    liveStats.data?.forEach(stats => {
      console.log('Game Stats:', stats);
    });
    ```

## Weekly Game Details

Get comprehensive game information with optional extras:

=== "Python"

    ```python
    details = nfl.games.get_weekly_game_details(
        season=2024,
        type_="REG",
        week=1,
        include_drive_chart=True,
        include_replays=True,
        include_standings=True,
        include_tagged_videos=False
    )

    for game_detail in details:
        print(f"Game: {game_detail.game}")
        print(f"Drive Chart: {game_detail.drive_chart}")
        print(f"Standings: {game_detail.standings}")
    ```

=== "TypeScript"

    ```typescript
    const details = await nfl.games.getWeeklyGameDetails(
      2024,   // season
      'REG',  // type
      1,      // week
      true,   // includeDriveChart
      true,   // includeReplays
      true,   // includeStandings
      false   // includeTaggedVideos
    );

    details.forEach(detail => {
      console.log('Game:', detail.game);
      console.log('Drive Chart:', detail.driveChart);
    });
    ```

## Team Information

Teams in game responses include:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Team identifier |
| `abbreviation` | string | 2-3 letter abbreviation (e.g., "KC") |
| `fullName` | string | Full team name |
| `nickName` | string | Team nickname |
| `score` | number | Current score |
| `record` | string | Win-loss record |

```python
for game in games.games:
    home = game.home_team
    away = game.away_team

    print(f"{away.full_name} ({away.record})")
    print(f"  @ {home.full_name} ({home.record})")
```

## Working with Game IDs

Game IDs are UUIDs used to fetch detailed game data:

```python
# Get games to find IDs
games = nfl.games.get_games(season=2024, season_type="REG", week=1)

# Use game ID for detailed data
for game in games.games:
    if game.game_status == "FINAL":
        box = nfl.games.get_box_score(game_id=game.id)
        pbp = nfl.games.get_play_by_play(game_id=game.id)
```
