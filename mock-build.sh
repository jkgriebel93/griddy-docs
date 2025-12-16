#!/bin/bash

export ROOT_DIR=`pwd`
export SCRIPT_DIR="$ROOT_DIR/scripts"
OPENAPI_REPO="jkgriebel93/griddy-docs"
PYTHON_SDK_REPO="jkgriebel93/griddy-sdk-python"
TYPESCRIPT_SDK_REPO="jkgriebel93/griddy-sdk-typescript"

echo ""
echo "Cleaning previous build artifacts..."
rm -rf "$ROOT_DIR/tmp/python-sdk"
rm -rf "$ROOT_DIR/tmp/typescript-sdk"
rm -rf "$ROOT_DIR/docs/site"
mkdir -p "$ROOT_DIR/tmp"



# git clone --depth 1 --single-branch "https://github.com/${PYTHON_SDK_REPO}.git" "$ROOT_DIR/tmp/python-sdk"
git clone "https://github.com/${TYPESCRIPT_SDK_REPO}.git" "$ROOT_DIR/tmp/typescript-sdk"

bash "$SCRIPT_DIR/build-typescript-docs.sh"
