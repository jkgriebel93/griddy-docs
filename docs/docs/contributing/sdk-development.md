# SDK Development

## Architecture

Both SDKs follow the same architecture:

```
src/griddy/
├── core/           # HTTP client, exceptions, utilities
├── settings.py     # Configuration
└── nfl/
    ├── sdk.py      # Main GriddyNFL class
    ├── basesdk.py  # Base SDK with endpoint execution
    ├── endpoints/  # API endpoint implementations
    │   ├── regular/    # Public NFL.com endpoints
    │   ├── pro/        # Pro API endpoints
    │   └── ngs/        # Next Gen Stats endpoints
    ├── models/     # Data models
    └── errors/     # Error classes
```

## Adding an Endpoint

### Python

1. Create endpoint class in `endpoints/`:

```python
from griddy.nfl.basesdk import BaseSDK, EndpointConfig

class NewEndpoint(BaseSDK):
    def get_data(self, param: str) -> ResponseType:
        config = EndpointConfig(
            method="GET",
            path="/api/path/{param}",
            request={"param": param},
            response_type=ResponseType,
        )
        return self._execute_endpoint(config)
```

2. Register in `sdk.py`:

```python
_sub_sdk_map = {
    "new_endpoint": ("griddy.nfl.endpoints.new", "NewEndpoint"),
}
```

### TypeScript

1. Create endpoint class:

```typescript
export class NewEndpoint extends BaseSDK {
    async getData(param: string): Promise<ResponseType> {
        const config = {
            method: "GET",
            path: "/api/path/{param}",
            request: { param },
        };
        return this.executeEndpoint(config);
    }
}
```

2. Add getter in `sdk.ts`:

```typescript
get newEndpoint(): NewEndpoint {
    if (!this._newEndpoint) {
        this._newEndpoint = new NewEndpoint(this.sdkConfiguration, this);
    }
    return this._newEndpoint;
}
```

## Code Style

### Python
- Black formatter (line-length 88)
- isort for imports
- mypy for type checking

### TypeScript
- Biome for linting/formatting
- Tab indentation, double quotes
