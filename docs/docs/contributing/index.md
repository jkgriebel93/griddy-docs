# Contributing

Thank you for your interest in contributing to Griddy! This guide will help you get started.

## Ways to Contribute

- **Bug Reports**: Open an issue with reproduction steps
- **Feature Requests**: Propose new features via issues
- **Code**: Submit pull requests for bug fixes or features
- **Documentation**: Improve or expand documentation

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## Development Setup

=== "Python SDK"

    ```bash
    git clone https://github.com/jkgriebel93/griddy-sdk-python.git
    cd griddy-sdk-python
    python -m venv venv
    source venv/bin/activate
    pip install -e ".[dev]"
    ```

=== "TypeScript SDK"

    ```bash
    git clone https://github.com/jkgriebel93/griddy-sdk-typescript.git
    cd griddy-sdk-typescript
    npm install
    npm run build
    ```

## Guidelines

- Follow existing code style
- Write tests for new features
- Update documentation as needed
- Keep commits focused and well-described

## Resources

- [Code of Conduct](code-of-conduct.md)
- [Testing](testing.md)
- [SDK Development](sdk-development.md)
- [Documentation](documentation.md)
