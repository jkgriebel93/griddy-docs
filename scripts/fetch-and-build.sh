#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Griddy Documentation Build Pipeline             ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Configuration - customize these for your repos
OPENAPI_REPO="jkgriebel93/griddy-docs"
PYTHON_SDK_REPO="jkgriebel93/griddy-sdk-python"
TYPESCRIPT_SDK_REPO="jkgriebel93/griddy-sdk-typescript"

export PYTHON_SDK_DIR="$ROOT_DIR/tmp/python-sdk"
export TYPESCRIPT_SDK_DIR="$ROOT_DIR/tmp/typescript-sdk"

# Clean previous build artifacts
echo "Step 1: Clean up to ensure fresh environment"
echo "Cleaning previous build artifacts..."
rm -rf "$PYTHON_SDK_DIR"
rm -rf "$TYPESCRIPT_SDK_DIR"
rm -rf "$ROOT_DIR/docs/site"
mkdir -p "$ROOT_DIR/tmp"

echo "Step 2: Install system deps, clone repos"
echo "Install pipx -> poetry"
sudo apt install -y pipx
pipx install poetry

git clone --depth 1 --single-branch "https://github.com/${PYTHON_SDK_REPO}.git" "$ROOT_DIR/tmp/python-sdk"
git clone --depth 1 --single-branch "https://github.com/${TYPESCRIPT_SDK_REPO}.git" "$ROOT_DIR/tmp/typescript-sdk"
echo "SDK repositories cloned"

echo "$TYPESCRIPT_SDK_DIR"
echo "Step 3: Build TypeScript SDK documentation"
bash "$SCRIPT_DIR/build-typescript-docs.sh"
echo "TypeScript SDK docs built"


echo "Step 4: Building Python SDK documentation..."
cd "$PYTHON_SDK_DIR"
poetry install --all-groups
eval $(poetry env activate)
echo "Python SDK installed."
cd "$ROOT_DIR"

echo "Step 5: Building OpenAPI documentation..."
bash "$SCRIPT_DIR/build-openapi-docs.sh"

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