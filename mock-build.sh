#!/bin/bash

export ROOT_DIR=`pwd`
export SCRIPT_DIR="$ROOT_DIR/scripts"
export SPEC_PATH="$ROOT_DIR/docs/docs/api-specs/nfl-com-api.yaml"

export PYTHON_SDK_REPO="jkgriebel93/griddy-sdk-python"
export TYPESCRIPT_SDK_REPO="jkgriebel93/griddy-sdk-typescript"

export PYTHON_SDK_DIR="$ROOT_DIR/tmp/python-sdk"
export TYPESCRIPT_SDK_DIR="$ROOT_DIR/tmp/typescript-sdk"

export PYTHON_DOCS_OUT="$ROOT_DIR/docs/docs/sdk-reference/python"
export TYPESCRIPT_DOCS_OUT="$ROOT_DIR/docs/docs/sdk-reference/typescript"
export OPENAPI_DOCS_OUT="$ROOT_DIR/docs/docs/api-reference"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "SPECS_PATH $SPEC_PATH"
echo "PYTHON_SDK_DIR: $PYTHON_SDK_DIR"
echo "TYPESCRIPT_SDK_DIR: $TYPESCRIPT_SDK_DIR"
echo "PYTHON_DOCS_OUT: $PYTHON_DOCS_OUT"
echo "TYPESCRIPT_DOCS_OUT: $TYPESCRIPT_DOCS_OUT"
echo "OPENAPI_DOCS_OUT: $OPENAPI_DOCS_OUT"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Griddy Documentation Build Pipeline             ║"
echo "╚══════════════════════════════════════════════════════════╝"


echo ""
echo "Step 1: Clean up to ensure fresh environment"
echo "Cleaning previous build artifacts..."
rm -rf "$PYTHON_SDK_DIR"
rm -rf "$TYPESCRIPT_SDK_DIR"
rm -rf "$ROOT_DIR/docs/site"
mkdir -p "$ROOT_DIR/tmp"



# git clone --depth 1 --single-branch "https://github.com/${PYTHON_SDK_REPO}.git" "$ROOT_DIR/tmp/python-sdk"
git clone "https://github.com/${TYPESCRIPT_SDK_REPO}.git" "$ROOT_DIR/tmp/typescript-sdk"

bash "$SCRIPT_DIR/build-typescript-docs.sh"
