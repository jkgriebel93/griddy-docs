#!/bin/bash
echo "Building OpenAPI documentation in $OPENAPI_DOCS_OUT"


# Build main NFL API docs
npx @redocly/cli build-docs \
    "$SPEC_PATH" \
    --config "$ROOT_DIR/config/redocly/redocly.yaml" \
    -o "$OPENAPI_DOCS_OUT/index.html"
  echo "NFL API reference built"

echo "OpenAPI docs built successfully"