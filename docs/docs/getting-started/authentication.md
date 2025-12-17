# Authentication

The Griddy SDK requires authentication to access NFL data. This guide explains how to obtain and use authentication tokens.

## Overview

The NFL API uses OAuth-based authentication. You need an access token to make API requests. There are two ways to authenticate:

1. **Token-based**: Provide a pre-obtained access token (both SDKs)
2. **Browser-based**: Automated login using Playwright (Python SDK only)

## Token-Based Authentication

### Obtaining a Token

To obtain an access token:

1. Log in to [NFL.com](https://www.nfl.com) in your browser
2. Open browser developer tools (F12)
3. Go to the Network tab
4. Look for API requests to `api.nfl.com`
5. Find the `Authorization` header containing `Bearer <token>`
6. Copy the token (without the "Bearer " prefix)

### Using the Token

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL

    # Using a pre-obtained token
    nfl = GriddyNFL(nfl_auth={"accessToken": "your_access_token_here"})

    # Make API calls
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    // Using a pre-obtained token
    const nfl = new GriddyNFL({
      nflAuth: { accessToken: 'your_access_token_here' }
    });

    // Make API calls
    const games = await nfl.games.getGames(2024, 'REG', 1);
    ```

### Token Format

The `nfl_auth` dictionary can include:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `accessToken` | string | Yes | The OAuth access token |
| `refreshToken` | string | No | Token for refreshing access |
| `expiresIn` | number | No | Token expiration in seconds |

## Browser-Based Authentication (Python Only)

The Python SDK can automatically obtain tokens using Playwright browser automation.

### Setup

First, install Playwright and browsers:

```bash
pip install playwright
playwright install chromium
```

### Usage

```python
from griddy.nfl import GriddyNFL

# Authenticate with email and password
nfl = GriddyNFL(
    login_email="your_email@example.com",
    login_password="your_password",
    headless_login=True  # Run browser in headless mode
)

# The SDK automatically handles authentication
games = nfl.games.get_games(season=2024, season_type="REG", week=1)
```

### Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `login_email` | str | None | NFL.com account email |
| `login_password` | str | None | NFL.com account password |
| `headless_login` | bool | False | Run browser without GUI |

!!! warning "Important"
    Browser-based authentication is not available in the TypeScript SDK. You must provide a pre-obtained access token.

## Storing Credentials

### Environment Variables

Store your token in an environment variable:

```bash
export NFL_ACCESS_TOKEN="your_token_here"
```

=== "Python"

    ```python
    import os
    from griddy.nfl import GriddyNFL

    token = os.environ.get("NFL_ACCESS_TOKEN")
    nfl = GriddyNFL(nfl_auth={"accessToken": token})
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL } from 'griddy-sdk';

    const token = process.env.NFL_ACCESS_TOKEN;
    const nfl = new GriddyNFL({ nflAuth: { accessToken: token! } });
    ```

### Configuration File

For development, you can store credentials in a local file:

```python
import json
from griddy.nfl import GriddyNFL

# Load from file
with open("credentials.json") as f:
    auth = json.load(f)

nfl = GriddyNFL(nfl_auth=auth)
```

!!! danger "Security Warning"
    Never commit credentials to version control. Add `credentials.json` to your `.gitignore` file.

## Token Expiration

NFL access tokens expire periodically. When your token expires:

1. API calls will return authentication errors
2. You'll need to obtain a new token

### Handling Expiration

=== "Python"

    ```python
    from griddy.nfl import GriddyNFL
    from griddy.core.exceptions import AuthenticationError

    try:
        games = nfl.games.get_games(season=2024, season_type="REG", week=1)
    except AuthenticationError:
        print("Token expired. Please obtain a new token.")
        # Re-authenticate or refresh token
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL, GriddyNFLDefaultError } from 'griddy-sdk';

    try {
      const games = await nfl.games.getGames(2024, 'REG', 1);
    } catch (error) {
      if (error instanceof GriddyNFLDefaultError && error.statusCode === 401) {
        console.log('Token expired. Please obtain a new token.');
      }
    }
    ```

## Context Manager (Python)

Use the context manager for automatic resource cleanup:

```python
from griddy.nfl import GriddyNFL

with GriddyNFL(nfl_auth={"accessToken": "your_token"}) as nfl:
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)
# Resources are automatically cleaned up
```

## Cleanup (TypeScript)

Always close the client when done:

```typescript
const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

try {
  const games = await nfl.games.getGames(2024, 'REG', 1);
} finally {
  nfl.close();
}
```
