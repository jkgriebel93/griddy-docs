# FAQ

## General

### What is Griddy?

Griddy is an SDK for accessing NFL data from multiple API endpoints, available in Python and TypeScript.

### Is Griddy affiliated with the NFL?

No. Griddy is an independent project and is not affiliated with, endorsed by, or connected to the NFL.

### Is Griddy free to use?

Yes, Griddy is open source. However, you need an NFL.com account to access the API.

## Authentication

### How do I get an access token?

Log in to NFL.com, open browser developer tools, and find the `Authorization` header in API requests. See the [Authentication guide](getting-started/authentication.md).

### My token expired. What do I do?

Obtain a new token from NFL.com. In Python, you can use browser-based authentication with Playwright for automatic token retrieval.

### Can I use the TypeScript SDK without a token?

No, the TypeScript SDK requires a pre-obtained token. Browser-based authentication is only available in Python.

## Usage

### What endpoints are available?

- **Regular API**: Games, rosters, standings, draft, combine
- **Pro API**: Stats (passing, rushing, receiving, defense), betting, players, transactions
- **Next Gen Stats**: Tracking stats, leaders, charts

### How do I handle rate limits?

The SDK includes retry configuration with exponential backoff. See the [Rate Limiting guide](guides/common-patterns/rate-limiting.md).

### Can I use async methods?

Yes. Python has `_async` suffixed methods. TypeScript methods are all async by default.

## Troubleshooting

### I get "Module not found" errors

Ensure you're using the correct Python version (3.14+) and have installed griddy:
```bash
pip install griddy
```

### API calls return 401 errors

Your token is expired or invalid. Obtain a new token from NFL.com.

### I can't find a specific endpoint

Check the [API Reference](api-reference/index.html) for available endpoints. Not all NFL API endpoints are implemented yet.

## Contributing

### How can I contribute?

See the [Contributing guide](contributing/index.md). We welcome bug reports, feature requests, and pull requests.

### Where do I report bugs?

Open an issue on GitHub:
- [Python SDK](https://github.com/jkgriebel93/griddy-sdk-python/issues)
- [TypeScript SDK](https://github.com/jkgriebel93/griddy-sdk-typescript/issues)
