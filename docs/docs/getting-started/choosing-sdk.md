# Choosing an SDK

Griddy offers both Python and TypeScript SDKs. This guide helps you choose the right one for your project.

## Feature Comparison

| Feature | Python SDK | TypeScript SDK |
|---------|------------|----------------|
| **Language Version** | Python 3.14+ | Node.js 18+ |
| **Package Name** | `griddy` | `griddy-sdk` |
| **Sync Methods** | Yes | No |
| **Async Methods** | Yes (`_async` suffix) | Yes (default) |
| **Type Safety** | Pydantic models | TypeScript interfaces |
| **Runtime Validation** | Yes (Pydantic) | No |
| **Browser Auth** | Yes (Playwright) | No |
| **Property Naming** | snake_case | camelCase |
| **Context Manager** | Yes (`with` statement) | No (manual `close()`) |

## When to Choose Python

Choose the Python SDK if you need:

### Browser-Based Authentication

Only Python supports automated browser login:

```python
nfl = GriddyNFL(
    login_email="user@example.com",
    login_password="password",
    headless_login=True
)
```

### Synchronous Operations

Python offers both sync and async methods:

```python
# Synchronous (blocking)
games = nfl.games.get_games(season=2024, season_type="REG", week=1)

# Asynchronous
games = await nfl.games.get_games_async(season=2024, season_type="REG", week=1)
```

### Runtime Data Validation

Pydantic models provide runtime validation:

```python
# Response data is validated against Pydantic models
games = nfl.games.get_games(season=2024, season_type="REG", week=1)

# Type-safe access with validation
for game in games.games:
    print(game.home_team.abbreviation)  # Validated at runtime
```

### Data Science & Analytics

Python integrates well with data science tools:

```python
import pandas as pd

games = nfl.games.get_games(season=2024, season_type="REG", week=1)
df = pd.DataFrame([g.dict() for g in games.games])
```

### Context Manager Support

Automatic resource cleanup with `with` statements:

```python
with GriddyNFL(nfl_auth=auth) as nfl:
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)
# Automatically cleaned up
```

## When to Choose TypeScript

Choose the TypeScript SDK if you need:

### Node.js Backend

Native integration with Node.js applications:

```typescript
import express from 'express';
import { GriddyNFL } from 'griddy-sdk';

const app = express();
const nfl = new GriddyNFL({ nflAuth: { accessToken: process.env.NFL_TOKEN! } });

app.get('/games', async (req, res) => {
  const games = await nfl.games.getGames(2024, 'REG', 1);
  res.json(games);
});
```

### Frontend Compatibility

Can be used in browser environments (with appropriate bundling):

```typescript
// Works with webpack, vite, etc.
import { GriddyNFL } from 'griddy-sdk';
```

### Compile-Time Type Safety

Full TypeScript type inference:

```typescript
// Types are inferred
const games = await nfl.games.getGames(2024, 'REG', 1);

// TypeScript catches errors at compile time
games.games?.forEach(game => {
  // IDE autocomplete and type checking
  console.log(game.homeTeam?.abbreviation);
});
```

### Native Async/Await

All methods are async by default:

```typescript
// Clean async/await syntax
const games = await nfl.games.getGames(2024, 'REG', 1);

// Easy concurrent requests
const [games, stats] = await Promise.all([
  nfl.games.getGames(2024, 'REG', 1),
  // other calls...
]);
```

### Modern JavaScript Ecosystem

Integration with modern JS tools:

```typescript
// Works with ESM and CommonJS
import { GriddyNFL } from 'griddy-sdk';
// or
const { GriddyNFL } = require('griddy-sdk');
```

## API Parity

Both SDKs provide access to the same API endpoints:

| Endpoint Category | Python | TypeScript |
|-------------------|--------|------------|
| Games | `nfl.games` | `nfl.games` |
| Rosters | `nfl.rosters` | Planned |
| Standings | `nfl.standings` | Planned |
| Stats | `nfl.stats.*` | Planned |
| Betting | `nfl.betting` | Planned |
| Next Gen Stats | `nfl.ngs.*` | Planned |

!!! note "TypeScript SDK Coverage"
    The TypeScript SDK currently implements the Games endpoint. Additional endpoints are being ported from the Python SDK.

## Code Comparison

### Getting Games

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL

    with GriddyNFL(nfl_auth={"accessToken": "token"}) as nfl:
        games = nfl.games.get_games(
            season=2024,
            season_type="REG",
            week=1
        )

        for game in games.games:
            print(f"{game.away_team.abbreviation} @ {game.home_team.abbreviation}")
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

    try {
      const games = await nfl.games.getGames(2024, 'REG', 1);

      games.games?.forEach(game => {
        console.log(`${game.awayTeam?.abbreviation} @ ${game.homeTeam?.abbreviation}`);
      });
    } finally {
      nfl.close();
    }
    ```

### Error Handling

=== "Python"

    ```python
    from griddy.core.exceptions import AuthenticationError, NotFoundError

    try:
        games = nfl.games.get_games(season=2024, season_type="REG", week=1)
    except AuthenticationError:
        print("Token expired")
    except NotFoundError:
        print("Not found")
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFLDefaultError } from 'griddy-sdk';

    try {
      const games = await nfl.games.getGames(2024, 'REG', 1);
    } catch (error) {
      if (error instanceof GriddyNFLDefaultError) {
        if (error.statusCode === 401) {
          console.log('Token expired');
        } else if (error.statusCode === 404) {
          console.log('Not found');
        }
      }
    }
    ```

## Recommendation Summary

| Use Case | Recommended SDK |
|----------|-----------------|
| Data science/analytics | Python |
| Backend API server (Node.js) | TypeScript |
| Backend API server (Python) | Python |
| Browser/frontend app | TypeScript |
| CLI tools | Either |
| Need browser auth | Python |
| Need sync methods | Python |
| Prefer compile-time types | TypeScript |
| Need runtime validation | Python |
