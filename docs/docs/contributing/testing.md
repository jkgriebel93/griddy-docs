# Testing

## Python SDK

### Running Tests

```bash
cd griddy-sdk-python

# Run all tests
pytest

# With coverage
pytest --cov=src/griddy --cov-report=html

# Run specific tests
pytest tests/test_nfl/test_endpoints/

# Skip slow tests
pytest -m "not slow"
```

### Test Structure

```
tests/
├── conftest.py          # Shared fixtures
├── fixtures/            # Test data
├── test_nfl/
│   ├── test_endpoints/  # Endpoint tests
│   └── test_models/     # Model tests
└── test_core/           # Core functionality tests
```

### Writing Tests

```python
import pytest
from unittest.mock import Mock

def test_get_games(mock_nfl_client):
    """Test getting games."""
    games = mock_nfl_client.games.get_games(
        season=2024, season_type="REG", week=1
    )
    assert len(games.games) > 0
```

## TypeScript SDK

### Running Tests

```bash
cd griddy-sdk-typescript

# Run tests
npm run test

# With coverage
npm run test:coverage

# Watch mode
npm run test -- --watch
```

### Test Structure

```
test/
├── setup.ts             # Test configuration
├── nfl/
│   ├── endpoints/       # Endpoint tests
│   └── models/          # Model tests
└── core/                # Core tests
```
