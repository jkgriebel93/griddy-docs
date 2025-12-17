# Testing Strategies

This guide covers strategies for testing code that uses the Griddy SDK.

## Mocking the SDK

### Using unittest.mock

```python
import unittest
from unittest.mock import Mock, patch, MagicMock
from griddy.nfl import GriddyNFL

class TestGameService(unittest.TestCase):

    def test_get_games(self):
        # Create mock response
        mock_game = Mock()
        mock_game.id = "game-123"
        mock_game.home_team.abbreviation = "KC"
        mock_game.away_team.abbreviation = "DET"
        mock_game.game_status = "FINAL"
        mock_game.home_team.score = 28
        mock_game.away_team.score = 24

        mock_response = Mock()
        mock_response.games = [mock_game]

        # Patch the SDK
        with patch.object(GriddyNFL, 'games') as mock_games:
            mock_games.get_games.return_value = mock_response

            nfl = GriddyNFL(nfl_auth={"accessToken": "test"})
            games = nfl.games.get_games(season=2024, season_type="REG", week=1)

            self.assertEqual(len(games.games), 1)
            self.assertEqual(games.games[0].home_team.abbreviation, "KC")

if __name__ == '__main__':
    unittest.main()
```

### Using pytest and pytest-mock

```python
import pytest
from unittest.mock import Mock
from griddy.nfl import GriddyNFL

@pytest.fixture
def mock_nfl(mocker):
    """Fixture providing mocked NFL client."""
    mock_client = Mock(spec=GriddyNFL)

    # Setup default mock responses
    mock_game = Mock()
    mock_game.id = "game-123"
    mock_game.home_team.abbreviation = "KC"
    mock_game.away_team.abbreviation = "DET"
    mock_game.game_status = "FINAL"

    mock_response = Mock()
    mock_response.games = [mock_game]

    mock_client.games.get_games.return_value = mock_response

    return mock_client

def test_get_games(mock_nfl):
    games = mock_nfl.games.get_games(season=2024, season_type="REG", week=1)

    assert len(games.games) == 1
    assert games.games[0].home_team.abbreviation == "KC"
    mock_nfl.games.get_games.assert_called_once_with(
        season=2024, season_type="REG", week=1
    )
```

## Fixtures for Common Data

```python
import pytest
from unittest.mock import Mock
from dataclasses import dataclass

@dataclass
class MockTeam:
    id: str
    abbreviation: str
    full_name: str
    score: int

@dataclass
class MockGame:
    id: str
    home_team: MockTeam
    away_team: MockTeam
    game_status: str
    season: int
    season_type: str
    week: int

@pytest.fixture
def sample_teams():
    """Fixture providing sample team data."""
    return {
        'KC': MockTeam(id='kc-123', abbreviation='KC', full_name='Kansas City Chiefs', score=28),
        'DET': MockTeam(id='det-123', abbreviation='DET', full_name='Detroit Lions', score=24),
        'SF': MockTeam(id='sf-123', abbreviation='SF', full_name='San Francisco 49ers', score=31),
    }

@pytest.fixture
def sample_games(sample_teams):
    """Fixture providing sample game data."""
    return [
        MockGame(
            id='game-1',
            home_team=sample_teams['KC'],
            away_team=sample_teams['DET'],
            game_status='FINAL',
            season=2024,
            season_type='REG',
            week=1
        ),
        MockGame(
            id='game-2',
            home_team=sample_teams['SF'],
            away_team=sample_teams['KC'],
            game_status='FINAL',
            season=2024,
            season_type='REG',
            week=2
        ),
    ]

def test_filter_by_team(sample_games):
    """Test filtering games by team."""
    team_abbr = 'KC'
    kc_games = [
        g for g in sample_games
        if g.home_team.abbreviation == team_abbr or
           g.away_team.abbreviation == team_abbr
    ]

    assert len(kc_games) == 2
```

## Testing Async Code

```python
import pytest
import asyncio
from unittest.mock import AsyncMock, Mock

@pytest.fixture
def mock_async_nfl():
    """Fixture for async mocked client."""
    mock_client = Mock()

    # Create async mock for async methods
    mock_game = Mock()
    mock_game.id = "game-123"

    mock_response = Mock()
    mock_response.games = [mock_game]

    mock_client.games.get_games_async = AsyncMock(return_value=mock_response)

    return mock_client

@pytest.mark.asyncio
async def test_async_get_games(mock_async_nfl):
    games = await mock_async_nfl.games.get_games_async(
        season=2024,
        season_type="REG",
        week=1
    )

    assert len(games.games) == 1
    mock_async_nfl.games.get_games_async.assert_awaited_once()
```

## Integration Testing

```python
import pytest
import os
from griddy.nfl import GriddyNFL

# Skip if no token available
pytestmark = pytest.mark.skipif(
    not os.environ.get('NFL_ACCESS_TOKEN'),
    reason="NFL_ACCESS_TOKEN not set"
)

class TestIntegration:
    @pytest.fixture(scope='class')
    def nfl(self):
        """Real SDK client for integration tests."""
        token = os.environ['NFL_ACCESS_TOKEN']
        return GriddyNFL(nfl_auth={"accessToken": token})

    def test_get_games_returns_data(self, nfl):
        """Integration test: verify games are returned."""
        games = nfl.games.get_games(
            season=2024,
            season_type="REG",
            week=1
        )

        assert games is not None
        assert hasattr(games, 'games')
        assert len(games.games) > 0

    def test_game_has_required_fields(self, nfl):
        """Integration test: verify game structure."""
        games = nfl.games.get_games(
            season=2024,
            season_type="REG",
            week=1
        )

        game = games.games[0]
        assert game.id is not None
        assert game.home_team is not None
        assert game.away_team is not None
        assert game.game_status is not None
```

## Testing Error Handling

```python
import pytest
from unittest.mock import Mock, patch
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import (
    AuthenticationError,
    NotFoundError,
    RateLimitError
)

def test_handles_authentication_error():
    """Test proper handling of auth errors."""
    with patch.object(GriddyNFL, 'games') as mock_games:
        mock_games.get_games.side_effect = AuthenticationError(
            "Token expired"
        )

        nfl = GriddyNFL(nfl_auth={"accessToken": "expired"})

        with pytest.raises(AuthenticationError):
            nfl.games.get_games(season=2024, season_type="REG", week=1)

def test_handles_rate_limit_error():
    """Test proper handling of rate limit errors."""
    with patch.object(GriddyNFL, 'games') as mock_games:
        mock_games.get_games.side_effect = RateLimitError(
            "Rate limit exceeded",
            retry_after=60
        )

        nfl = GriddyNFL(nfl_auth={"accessToken": "test"})

        with pytest.raises(RateLimitError) as exc_info:
            nfl.games.get_games(season=2024, season_type="REG", week=1)

        assert exc_info.value.retry_after == 60

def test_retry_on_rate_limit(mocker):
    """Test retry logic on rate limit."""
    mock_games = mocker.patch.object(GriddyNFL, 'games')

    # First call fails, second succeeds
    mock_response = Mock()
    mock_response.games = []

    mock_games.get_games.side_effect = [
        RateLimitError("Rate limited", retry_after=1),
        mock_response
    ]

    nfl = GriddyNFL(nfl_auth={"accessToken": "test"})

    # Your retry logic function
    def get_with_retry(func, max_retries=2):
        import time
        for i in range(max_retries):
            try:
                return func()
            except RateLimitError as e:
                if i < max_retries - 1:
                    time.sleep(0.1)  # Short sleep for test
                else:
                    raise

    result = get_with_retry(
        lambda: nfl.games.get_games(season=2024, season_type="REG", week=1)
    )

    assert result.games == []
    assert mock_games.get_games.call_count == 2
```

## Test Configuration

```python
# conftest.py
import pytest
from unittest.mock import Mock

@pytest.fixture(autouse=True)
def reset_mocks():
    """Reset mocks between tests."""
    yield
    # Cleanup if needed

@pytest.fixture
def mock_nfl_factory():
    """Factory fixture for creating configured mocks."""
    def _create_mock(games=None, stats=None):
        mock = Mock()

        if games:
            mock_response = Mock()
            mock_response.games = games
            mock.games.get_games.return_value = mock_response

        if stats:
            mock.stats.passing.get_passing_stats_by_season.return_value = stats

        return mock

    return _create_mock

def test_with_factory(mock_nfl_factory):
    mock_game = Mock()
    mock_game.id = "game-123"

    nfl = mock_nfl_factory(games=[mock_game])

    games = nfl.games.get_games(season=2024, season_type="REG", week=1)
    assert len(games.games) == 1
```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_games.py

# Run tests matching pattern
pytest -k "test_get_games"

# Run async tests
pytest --asyncio-mode=auto

# Run integration tests only
pytest -m integration
```
