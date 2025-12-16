#!/bin/bash

set -e
export ROOT_DIR=$1
export SCRIPT_DIR="$ROOT_DIR/scrips"
export SPEC_PATH="$ROOT_DIR/docs/docs/openapi/nfl-com-api.yaml"

export PYTHON_SDK_REPO="jkgriebel93/griddy-sdk-python"
export TYPESCRIPT_SDK_REPO="jkgriebel93/griddy-sdk-typescript"

export PYTHON_SDK_DIR="$ROOT_DIR/tmp/python-sdk"
export TYPESCRIPT_SDK_DIR="$ROOT_DIR/tmp/typescript-sdk"

export PYTHON_DOCS_OUT="$ROOT_DIR/docs/docs/sdk-reference/python"
export TYPESCRIPT_DOCS_OUT="$ROOT_DIR/docs/docs/sdk-reference/typescript"
export OPENAPI_DOCS_OUT="$ROOT_DIR/docs/docs/api-reference"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "ROOT_DIR: $ROOT_DIR"
echo "SPECS_PATH $SPEC_PATH"
echo "PYTHON_SDK_DIR: $PYTHON_SDK_DIR"
echo "TYPESCRIPT_SDK_DIR: $TYPESCRIPT_SDK_DIR"
echo "PYTHON_DOCS_OUT: $PYTHON_DOCS_OUT"
echo "TYPESCRIPT_DOCS_OUT: $TYPESCRIPT_DOCS_OUT"
echo "OPENAPI_DOCS_OUT: $OPENAPI_DOCS_OUT"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Griddy Documentation Build Pipeline             ║"
echo "╚══════════════════════════════════════════════════════════╝"

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

git clone "https://github.com/${PYTHON_SDK_REPO}.git" "$PYTHON_SDK_DIR"
git clone "https://github.com/${TYPESCRIPT_SDK_REPO}.git" "$TYPESCRIPT_SDK_DIR"
echo "SDK repositories cloned"

ls -lah "$TYPESCRIPT_SDK_DIR"

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
cd "$ROOT_DIR"

pwd
ls -lah
# tree .

# Step 6: Build final MkDocs site
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