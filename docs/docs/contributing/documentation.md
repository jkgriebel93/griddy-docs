# Documentation

## Structure

Documentation is built with MkDocs Material and lives in `griddy-docs/`:

```
griddy-docs/
├── docs/
│   ├── mkdocs.yml       # MkDocs configuration
│   └── docs/            # Documentation source
│       ├── index.md
│       ├── getting-started/
│       ├── guides/
│       ├── examples/
│       └── tutorials/
└── scripts/             # Build scripts
```

## Local Development

```bash
cd griddy-docs/docs

# Install dependencies
pip install mkdocs-material mkdocstrings[python]

# Serve locally
mkdocs serve

# Build
mkdocs build
```

## Writing Documentation

### Style Guide

- Use clear, concise language
- Include code examples for both Python and TypeScript
- Use admonitions for notes and warnings:

```markdown
!!! note
    This is a note.

!!! warning
    This is a warning.
```

### Code Blocks

Use tabs for multi-language examples:

```markdown
=== "Python"
    ```python
    # Python code
    ```

=== "TypeScript"
    ```typescript
    // TypeScript code
    ```
```

## API Documentation

Python SDK API docs are generated from docstrings using mkdocstrings. TypeScript docs use TypeDoc.
