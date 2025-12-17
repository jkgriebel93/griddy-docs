# Installation

This guide covers installing the Griddy SDK for both Python and TypeScript.

## Python SDK

### Requirements

- Python 3.14 or higher
- pip or poetry for package management

### Basic Installation

Install from PyPI:

```bash
pip install griddy
```

### Development Installation

For development with testing and documentation tools:

```bash
pip install griddy[dev]
```

This includes:

- pytest, pytest-cov, pytest-mock for testing
- black, isort, flake8 for code formatting
- mypy for type checking
- pre-commit for git hooks

### Documentation Dependencies

To build documentation locally:

```bash
pip install griddy[docs]
```

### From Source

Clone and install in development mode:

```bash
git clone https://github.com/jkgriebel93/griddy-sdk-python.git
cd griddy-sdk-python

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install in editable mode
pip install -e ".[dev]"
```

### Playwright Setup (Optional)

For browser-based authentication, install Playwright browsers:

```bash
playwright install chromium
```

## TypeScript SDK

### Requirements

- Node.js 18.0.0 or higher
- npm, yarn, or pnpm for package management

### Basic Installation

Using npm:

```bash
npm install griddy-sdk
```

Using yarn:

```bash
yarn add griddy-sdk
```

Using pnpm:

```bash
pnpm add griddy-sdk
```

### From Source

Clone and build from source:

```bash
git clone https://github.com/jkgriebel93/griddy-sdk-typescript.git
cd griddy-sdk-typescript

# Install dependencies
npm install

# Build the SDK
npm run build
```

### TypeScript Configuration

The SDK requires TypeScript 5.0+ for full type support. Recommended `tsconfig.json` settings:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

## Verifying Installation

### Python

```python
from griddy.nfl import GriddyNFL
print("Griddy SDK installed successfully!")
```

### TypeScript

```typescript
import { GriddyNFL } from 'griddy-sdk';
console.log("Griddy SDK installed successfully!");
```

## Troubleshooting

### Python: Module Not Found

If you get `ModuleNotFoundError`, ensure you're using the correct Python version:

```bash
python --version  # Should be 3.14+
pip show griddy   # Check installation
```

### TypeScript: Type Errors

Ensure your TypeScript version is compatible:

```bash
npx tsc --version  # Should be 5.0+
```

### Playwright Issues

If browser authentication fails, try reinstalling Playwright:

```bash
pip uninstall playwright
pip install playwright
playwright install chromium
```
