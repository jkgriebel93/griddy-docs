# SDK Reference

Complete API reference documentation for Griddy SDKs, auto-generated from source code.

## Available SDKs

<div class="grid cards" markdown>

-   :fontawesome-brands-python:{ .lg .middle } __Python SDK__

    ---

    Full-featured SDK with async support, type hints, and Pydantic models.

    [:octicons-arrow-right-24: Python Reference](python/)

-   :fontawesome-brands-js:{ .lg .middle } __TypeScript SDK__

    ---

    Type-safe SDK for Node.js and browser environments.

    [:octicons-arrow-right-24: TypeScript Reference](typescript/index.html)

</div>

## SDK Comparison
**Note:** The Typescript SDK is a roadmap item at this time (December 2025), i.e. it doesn't exist yet.
| Feature | Python | TypeScript |
|---------|--------|------------|
| Async Support | ✅ (httpx) | ✅ (native) |
| Type Safety | ✅ (type hints) | ✅ (TypeScript) |
| Data Models | Pydantic | Zod |
| Auto Token Refresh | ✅ | ✅ |
| Pro API Support | ✅ | ✅ |

## Docstring Format

Both SDKs use Google-style docstrings. Example:
```python
def get_player(self, player_id: str) -> Player:
    """Fetch a player by their NFL ID.
    
    Args:
        player_id: The unique NFL player identifier.
    
    Returns:
        Player object with full profile data.
    
    Raises:
        NotFoundError: If the player doesn't exist.
        AuthenticationError: If Pro API auth is required but missing.
    
    Example:
        >>> client = NFLClient()
        >>> player = client.players.get("00-0023459")
        >>> print(player.display_name)
        'Patrick Mahomes'
    """
```