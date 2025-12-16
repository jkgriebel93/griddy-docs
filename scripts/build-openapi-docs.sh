#!/bin/bash

OUTPUT_DIR="$ROOT_DIR/docs/docs/api-reference"

echo "Building OpenAPI documentation in $OUTPUT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build main NFL API docs
if [ -f "$SPECS_DIR/nfl-com-api.yaml" ]; then
  npx @redocly/cli build-docs \
    "$SPECS_DIR/nfl-com-api.yaml" \
    --config "$ROOT_DIR/config/redocly/redocly.yaml" \
    -o "$OUTPUT_DIR/index.html"
  echo "NFL API reference built"
fi

echo "OpenAPI docs built successfully"