# Griddy - NFL API Documentation

Welcome to the complete documentation for Griddy, your NFL API SDK toolkit.

<div class="grid cards" markdown>

-   :material-clock-fast:{ .lg .middle } __Get Started in 5 Minutes__

    ---

    Install the SDK and make your first API call

    [:octicons-arrow-right-24: Getting Started](getting-started/index.md)

-   :material-book-open-variant:{ .lg .middle } __Explore the Guides__

    ---

    Deep dives into authentication, data models, and advanced patterns

    [:octicons-arrow-right-24: Guides](guides/index.md)

-   :material-api:{ .lg .middle } __API Reference__

    ---

    Complete OpenAPI reference for all NFL API endpoints

    [:octicons-arrow-right-24: API Reference](api-reference/index.html)

-   :material-code-braces:{ .lg .middle } __SDK Reference__

    ---

    Auto-generated documentation for Python and TypeScript SDKs

    [:octicons-arrow-right-24: Python SDK](sdk-reference/python/index.html) · [:octicons-arrow-right-24: TypeScript SDK](sdk-reference/typescript/index.html)

</div>

## Quick Install

=== "Python"
```bash
    pip install griddy-nfl
```

=== "TypeScript"
```bash
    npm install @griddy/nfl-sdk
```

## Feature Highlights

- **🔐 Smart Authentication** - Automatic token refresh with thread-safe operations
- **📊 Complete API Coverage** - Access to both public NFL API and premium Pro API
- **🔄 Type Safety** - Full type hints (Python) and TypeScript definitions
- **⚡ Async Support** - Built on httpx for modern async/await patterns

!!! pro "Pro API Features"

    Endpoints under `/api/secured/*` require a Pro API subscription. 
    [Learn more about authentication](guides/authentication/pro-api-auth.md)