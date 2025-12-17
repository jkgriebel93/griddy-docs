# Error Handling

This guide covers comprehensive error handling strategies for the Griddy SDK.

## Exception Hierarchy

### Python

The Python SDK provides a hierarchy of exceptions:

```
GriddyError (Base)
├── APIError           - General API request failures
├── RateLimitError     - Rate limit exceeded (429)
├── NotFoundError      - Resource not found (404)
├── AuthenticationError - Authentication failed (401)
└── ValidationError    - Request validation failures
```

```python
from griddy.core.exceptions import (
    GriddyError,
    APIError,
    RateLimitError,
    NotFoundError,
    AuthenticationError,
    ValidationError
)
```

### TypeScript

```typescript
import {
  GriddyNFLError,         // Base error class
  GriddyNFLDefaultError,  // API errors with status codes
  NoResponseError         // Network/timeout errors
} from 'griddy-sdk';
```

## Basic Error Handling

### Python

```python
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import (
    GriddyError,
    AuthenticationError,
    NotFoundError,
    RateLimitError
)

nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

try:
    games = nfl.games.get_games(season=2024, season_type="REG", week=1)

except AuthenticationError:
    print("Authentication failed. Token may be expired.")

except NotFoundError as e:
    print(f"Resource not found: {e.message}")

except RateLimitError as e:
    wait_time = e.retry_after or 60
    print(f"Rate limited. Retry after {wait_time} seconds.")

except GriddyError as e:
    print(f"API error: {e.message}")
    print(f"Status code: {e.status_code}")
    print(f"Response: {e.response_data}")
```

### TypeScript

```typescript
import {
  GriddyNFL,
  GriddyNFLError,
  GriddyNFLDefaultError,
  NoResponseError
} from 'griddy-sdk';

const nfl = new GriddyNFL({ nflAuth: { accessToken: 'token' } });

try {
  const games = await nfl.games.getGames(2024, 'REG', 1);
} catch (error) {
  if (error instanceof GriddyNFLDefaultError) {
    console.error('API Error:', error.message);
    console.error('Status:', error.statusCode);
    console.error('Response:', error.responseText);

    switch (error.statusCode) {
      case 401:
        console.error('Authentication failed');
        break;
      case 404:
        console.error('Resource not found');
        break;
      case 429:
        console.error('Rate limited');
        break;
      default:
        console.error('Unknown API error');
    }
  } else if (error instanceof NoResponseError) {
    console.error('Network error - no response received');
  } else if (error instanceof GriddyNFLError) {
    console.error('SDK error:', error.message);
  } else {
    console.error('Unexpected error:', error);
  }
}
```

## Error Recovery Strategies

### Retry with Backoff

```python
import time
from typing import TypeVar, Callable
from griddy.core.exceptions import GriddyError, RateLimitError

T = TypeVar('T')

def retry_with_backoff(
    func: Callable[[], T],
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0
) -> T:
    """Retry function with exponential backoff."""
    last_exception = None

    for attempt in range(max_retries):
        try:
            return func()

        except RateLimitError as e:
            wait_time = e.retry_after or min(base_delay * (2 ** attempt), max_delay)
            print(f"Rate limited. Waiting {wait_time}s (attempt {attempt + 1}/{max_retries})")
            time.sleep(wait_time)
            last_exception = e

        except GriddyError as e:
            if e.status_code and e.status_code >= 500:
                # Server error - retry
                wait_time = min(base_delay * (2 ** attempt), max_delay)
                print(f"Server error. Waiting {wait_time}s (attempt {attempt + 1}/{max_retries})")
                time.sleep(wait_time)
                last_exception = e
            else:
                # Client error - don't retry
                raise

    raise last_exception or Exception("Max retries exceeded")

# Usage
games = retry_with_backoff(
    lambda: nfl.games.get_games(season=2024, season_type="REG", week=1)
)
```

### Circuit Breaker

```python
import time
from enum import Enum
from typing import Callable, TypeVar

T = TypeVar('T')

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing if service recovered

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 30.0
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failures = 0
        self.last_failure_time = 0
        self.state = CircuitState.CLOSED

    def call(self, func: Callable[[], T]) -> T:
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is open")

        try:
            result = func()
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise

    def _on_success(self):
        self.failures = 0
        self.state = CircuitState.CLOSED

    def _on_failure(self):
        self.failures += 1
        self.last_failure_time = time.time()

        if self.failures >= self.failure_threshold:
            self.state = CircuitState.OPEN

# Usage
breaker = CircuitBreaker(failure_threshold=5, recovery_timeout=30)

try:
    games = breaker.call(
        lambda: nfl.games.get_games(season=2024, season_type="REG", week=1)
    )
except Exception as e:
    print(f"Request failed: {e}")
```

### Fallback Data

```python
from typing import Optional

class NFLClientWithFallback:
    def __init__(self, nfl: GriddyNFL):
        self.nfl = nfl
        self._cache = {}

    def get_games(
        self,
        season: int,
        season_type: str,
        week: int
    ):
        cache_key = f"{season}:{season_type}:{week}"

        try:
            games = self.nfl.games.get_games(
                season=season,
                season_type=season_type,
                week=week
            )
            # Cache successful response
            self._cache[cache_key] = games
            return games

        except GriddyError as e:
            # Try to return cached data
            if cache_key in self._cache:
                print(f"API error, returning cached data: {e.message}")
                return self._cache[cache_key]

            # No cached data available
            raise
```

## Logging Errors

```python
import logging
from griddy.core.exceptions import GriddyError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def logged_api_call(func):
    """Decorator to log API errors."""
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except GriddyError as e:
            logger.error(
                f"API Error: {e.message}",
                extra={
                    'status_code': e.status_code,
                    'response': e.response_data,
                    'function': func.__name__,
                    'args': args,
                    'kwargs': kwargs
                }
            )
            raise
    return wrapper

@logged_api_call
def get_games(nfl, season, season_type, week):
    return nfl.games.get_games(
        season=season,
        season_type=season_type,
        week=week
    )
```

## Graceful Degradation

```python
from dataclasses import dataclass
from typing import Optional, List

@dataclass
class GameResult:
    games: List
    from_cache: bool
    error: Optional[str]

class ResilientNFLClient:
    def __init__(self, nfl: GriddyNFL):
        self.nfl = nfl
        self._cache = {}
        self._error_count = 0

    def get_games(
        self,
        season: int,
        season_type: str,
        week: int
    ) -> GameResult:
        cache_key = f"{season}:{season_type}:{week}"

        try:
            games = self.nfl.games.get_games(
                season=season,
                season_type=season_type,
                week=week
            )
            self._cache[cache_key] = games
            self._error_count = 0
            return GameResult(games=games.games, from_cache=False, error=None)

        except AuthenticationError as e:
            # Authentication errors are critical - don't mask
            raise

        except GriddyError as e:
            self._error_count += 1

            # Return cached data if available
            if cache_key in self._cache:
                return GameResult(
                    games=self._cache[cache_key].games,
                    from_cache=True,
                    error=str(e.message)
                )

            # Return empty result with error
            return GameResult(
                games=[],
                from_cache=False,
                error=str(e.message)
            )

# Usage
client = ResilientNFLClient(nfl)
result = client.get_games(2024, "REG", 1)

if result.error:
    print(f"Warning: {result.error}")
    if result.from_cache:
        print("Using cached data")

for game in result.games:
    print(game)
```

## Best Practices

1. **Catch specific exceptions**: Handle different error types differently
2. **Always have a fallback**: Catch the base exception as a last resort
3. **Log errors with context**: Include request parameters and response data
4. **Implement retry logic**: Use exponential backoff for transient errors
5. **Don't swallow errors**: Re-raise or handle appropriately
6. **Use circuit breakers**: Prevent cascading failures
7. **Provide fallback data**: Return cached or default data when possible
8. **Monitor error rates**: Track and alert on error patterns
