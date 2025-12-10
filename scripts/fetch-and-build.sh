#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Griddy Documentation Build Pipeline             ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Configuration - customize these for your repos
OPENAPI_REPO="your-org/griddy-sdk-sources"
PYTHON_SDK_REPO="your-org/griddy-sdk-python"
TYPESCRIPT_SDK_REPO="your-org/griddy-sdk-typescript"

# Clean previous build artifacts
echo ""
echo "Cleaning previous build artifacts..."
rm -rf "$ROOT_DIR/tmp/openapi-specs"
rm -rf "$ROOT_DIR/tmp/python-sdk"
rm -rf "$ROOT_DIR/tmp/typescript-sdk"
mkdir -p "$ROOT_DIR/tmp"

# Step 1: Fetch OpenAPI specs
echo ""
echo "Step 1/5: Fetching OpenAPI specifications..."
mkdir -p "$ROOT_DIR/tmp/openapi-specs"
curl -sL "https://raw.githubusercontent.com/${OPENAPI_REPO}/main/openapi/nfl-com-api.yaml" \
  -o "$ROOT_DIR/tmp/openapi-specs/nfl-api.yaml"
curl -sL "https://raw.githubusercontent.com/${OPENAPI_REPO}/main/openapi/nfl-pro-api.yaml" \
  -o "$ROOT_DIR/tmp/openapi-specs/nfl-pro-api.yaml" || echo "Pro API spec not found, skipping..."

echo "   ✓ OpenAPI specs fetched"

# Step 2: Clone SDK repositories
echo ""
echo "Step 2/5: Cloning SDK repositories..."
git clone --depth 1 --single-branch "https://github.com/${PYTHON_SDK_REPO}.git" "$ROOT_DIR/tmp/python-sdk"
git clone --depth 1 --single-branch "https://github.com/${TYPESCRIPT_SDK_REPO}.git" "$ROOT_DIR/tmp/typescript-sdk"

echo "   ✓ SDK repositories cloned"

# Step 3: Build Python SDK documentation
echo ""
echo "Step 3/5: Building Python SDK documentation..."
bash "$SCRIPT_DIR/build-python-docs.sh"
echo "   ✓ Python SDK docs built"

# Step 4: Build TypeScript SDK documentation
echo ""
echo "Step 4/5: Building TypeScript SDK documentation..."
bash "$SCRIPT_DIR/build-typescript-docs.sh"
echo "   ✓ TypeScript SDK docs built"

# Step 5: Build OpenAPI documentation
echo ""
echo "Step 5/5: Building OpenAPI documentation..."
bash "$SCRIPT_DIR/build-openapi-docs.sh"
echo "   ✓ OpenAPI docs built"

# Step 6: Build final MkDocs site
echo ""
echo "Building MkDocs site..."
cd "$ROOT_DIR/docs"
mkdocs build

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                  Build Complete!                         ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Output: docs/site/                                      ║"
echo "║  Preview: cd docs && mkdocs serve                        ║"
echo "╚══════════════════════════════════════════════════════════╝"