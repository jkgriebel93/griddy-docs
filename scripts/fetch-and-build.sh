#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Griddy Documentation Build Pipeline             ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Configuration - customize these for your repos
OPENAPI_REPO="jkgriebel93/griddy-docs"
PYTHON_SDK_REPO="jkgriebel93/griddy-sdk-python"
# TYPESCRIPT_SDK_REPO="jkgriebel93/griddy-sdk-typescript"

# Clean previous build artifacts
echo ""
echo "Cleaning previous build artifacts..."
rm -rf "$ROOT_DIR/tmp/python-sdk"
# rm -rf "$ROOT_DIR/tmp/typescript-sdk"
rm -rf "$ROOT_DIR/docs/site"
mkdir -p "$ROOT_DIR/tmp"

# Step 1: Clone SDK repositories
echo ""
echo "Step 2/5: Cloning SDK repositories..."
git clone --depth 1 --single-branch "https://github.com/${PYTHON_SDK_REPO}.git" "$ROOT_DIR/tmp/python-sdk"
# git clone --depth 1 --single-branch "https://github.com/${TYPESCRIPT_SDK_REPO}.git" "$ROOT_DIR/tmp/typescript-sdk"

echo "   ✓ SDK repositories cloned"

# Step 2.5 Install pipx, poetry
sudo apt install -y pipx
pipx install poetry


# Step 3: Install Python SDK so mkdocstrings can access it.
echo ""
echo "Step 3/5: Building Python SDK documentation..."
cd "$ROOT_DIR/tmp/python-sdk"
poetry install --all-groups
eval $(poetry env activate)
echo "Python SDK installed."

# Step 4: Build TypeScript SDK documentation
# echo ""
# echo "Step 4/5: Building TypeScript SDK documentation..."
# bash "$SCRIPT_DIR/build-typescript-docs.sh"
# echo "   ✓ TypeScript SDK docs built"

# Step 5: Build OpenAPI documentation
echo ""
echo "Step 5/5: Building OpenAPI documentation..."
bash "$SCRIPT_DIR/build-openapi-docs.sh"
echo "   ✓ OpenAPI docs built"

# Step 6: Build final MkDocs site
echo ""
echo "Building MkDocs site..."
cd "$ROOT_DIR/docs"
mkdocs build --strict

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                  Build Complete!                         ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Output: docs/site/                                      ║"
echo "║  Preview: cd docs && mkdocs serve                        ║"
echo "╚══════════════════════════════════════════════════════════╝"