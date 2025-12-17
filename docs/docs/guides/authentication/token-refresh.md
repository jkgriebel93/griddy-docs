# Token Refresh

NFL access tokens expire periodically. This guide explains how to handle token expiration and refresh.

## Token Expiration

Access tokens typically expire after a set period. When a token expires:

- API calls return 401 Unauthorized errors
- You need to obtain a new token

## Detecting Expiration

### Python

```python
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import AuthenticationError

nfl = GriddyNFL(nfl_auth={"accessToken": "your_token"})

try:
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)
except AuthenticationError:
    print("Token expired - need to re-authenticate")
```

### TypeScript

```typescript
import { GriddyNFL, GriddyNFLDefaultError } from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'your_token' } });

try {
  const games = await nfl.games.getGames(2024, 'REG', 1);
} catch (error) {
  if (error instanceof GriddyNFLDefaultError && error.statusCode === 401) {
    console.log('Token expired - need to re-authenticate');
  }
}
```

## Refresh Strategy

### Manual Refresh

The simplest approach is to obtain a new token when the current one expires:

=== "Python"

    ```python
    import json
    from griddy.nfl import GriddyNFL
    from griddy.core.exceptions import AuthenticationError

    def get_client():
        """Get an authenticated client, refreshing token if needed."""
        try:
            # Try to use cached token
            with open("creds.json") as f:
                auth = json.load(f)
            nfl = GriddyNFL(nfl_auth=auth)

            # Test the token
            nfl.games.get_games(season=2024, season_type="REG", week=1)
            return nfl

        except (FileNotFoundError, AuthenticationError):
            # Token missing or expired - re-authenticate
            nfl = GriddyNFL(
                login_email="user@example.com",
                login_password="password",
                headless_login=True
            )
            return nfl
    ```

=== "TypeScript"

    ```typescript
    import { GriddyNFL, GriddyNFLDefaultError } from 'griddy-sdk';
    import fs from 'fs';

    async function getClient(): Promise<GriddyNFL> {
      try {
        // Try to use cached token
        const auth = JSON.parse(fs.readFileSync('creds.json', 'utf-8'));
        const nfl = new GriddyNFL({ nflAuth: auth });

        // Test the token
        await nfl.games.getGames(2024, 'REG', 1);
        return nfl;

      } catch (error) {
        if (error instanceof GriddyNFLDefaultError && error.statusCode === 401) {
          throw new Error('Token expired. Please obtain a new token manually.');
        }
        throw error;
      }
    }
    ```

### Wrapper with Auto-Retry

Create a wrapper that automatically retries on authentication failure:

```python
import json
from functools import wraps
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import AuthenticationError

class NFLClient:
    def __init__(self, email: str, password: str):
        self.email = email
        self.password = password
        self._client = None
        self._load_or_authenticate()

    def _load_or_authenticate(self):
        """Load cached token or authenticate."""
        try:
            with open("creds.json") as f:
                auth = json.load(f)
            self._client = GriddyNFL(nfl_auth=auth)
        except FileNotFoundError:
            self._authenticate()

    def _authenticate(self):
        """Perform browser authentication."""
        self._client = GriddyNFL(
            login_email=self.email,
            login_password=self.password,
            headless_login=True
        )

    def _with_refresh(self, func):
        """Execute function with automatic token refresh."""
        try:
            return func()
        except AuthenticationError:
            self._authenticate()
            return func()

    def get_games(self, season: int, season_type: str, week: int):
        return self._with_refresh(
            lambda: self._client.games.get_games(
                season=season,
                season_type=season_type,
                week=week
            )
        )

# Usage
client = NFLClient("user@example.com", "password")
games = client.get_games(2024, "REG", 1)
```

## Token Information

The `nfl_auth` dictionary can contain additional token information:

```python
auth = {
    "accessToken": "the_access_token",
    "refreshToken": "optional_refresh_token",
    "expiresIn": 3600  # Expiration in seconds
}
```

### Checking Expiration Time

If the API provides expiration information:

```python
import time
import json

def is_token_expired(auth: dict) -> bool:
    """Check if token is expired based on stored expiration."""
    if "expiresAt" not in auth:
        return False  # Unknown expiration

    return time.time() > auth["expiresAt"]

def save_token_with_expiry(auth: dict):
    """Save token with calculated expiration timestamp."""
    if "expiresIn" in auth:
        auth["expiresAt"] = time.time() + auth["expiresIn"]

    with open("creds.json", "w") as f:
        json.dump(auth, f)
```

## Best Practices

1. **Cache tokens**: Don't authenticate on every request
2. **Handle gracefully**: Always catch authentication errors
3. **Refresh proactively**: Refresh before expiration when possible
4. **Log refresh events**: Track when tokens are refreshed for debugging
5. **Secure storage**: Store tokens securely, not in plaintext

## Rate Limiting Considerations

Avoid excessive re-authentication:

```python
import time

class TokenManager:
    def __init__(self):
        self.last_auth_time = 0
        self.min_auth_interval = 60  # Minimum seconds between auth attempts

    def can_authenticate(self) -> bool:
        return time.time() - self.last_auth_time > self.min_auth_interval

    def mark_authenticated(self):
        self.last_auth_time = time.time()
```
