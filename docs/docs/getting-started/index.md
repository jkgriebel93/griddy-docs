# Getting Started

This guide will get you up and running with the Griddy NFL API SDK in under 5 minutes.

## Prerequisites

Before you begin, ensure you have:

- Python 3.9+ or Node.js 18+
- An NFL.com account (for Pro API access)

## Installation

=== "Python"
```bash
    pip install griddy-nfl
```

    Or with Poetry:
```bash
    poetry add griddy-nfl
```

=== "TypeScript"
```bash
    npm install @griddy/nfl-sdk
```

    Or with Yarn:
```bash
    yarn add @griddy/nfl-sdk
```

## Your First API Call

=== "Python"
```python
    from griddy import NFLClient

    # Create client (uses public API, no auth needed)
    client = NFLClient()

    # Fetch current week's schedule
    schedule = client.schedules.get_current()
    
    for game in schedule.games:
        print(f"{game.away_team} @ {game.home_team}")
```

=== "TypeScript"
```typescript
    import { NFLClient } from '@griddy/nfl-sdk';

    // Create client
    const client = new NFLClient();

    // Fetch current week's schedule
    const schedule = await client.schedules.getCurrent();
    
    for (const game of schedule.games) {
      console.log(`${game.awayTeam} @ ${game.homeTeam}`);
    }
```

## Next Steps

<div class="grid cards" markdown>

-   [:octicons-key-16: __Authentication__](authentication.md)

    Set up authentication for Pro API access

-   [:octicons-code-16: __Python Quickstart__](quickstart-python.md)

    Complete walkthrough for Python developers

</div>