#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Validating documentation links..."

cd "$ROOT_DIR/docs"

# Build site first if not exists
if [ ! -d "site" ]; then
  mkdocs build
fi

# Use linkchecker if available
if command -v linkchecker &> /dev/null; then
  linkchecker site/index.html --check-extern --no-robots
else
  echo "linkchecker not installed, skipping validation"
  echo "Install with: pip install linkchecker"
fi