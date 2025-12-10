#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON_SDK_DIR="$ROOT_DIR/tmp/python-sdk"
OUTPUT_DIR="$ROOT_DIR/docs/docs/sdk-reference/python"

echo "Building Python SDK documentation..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Install SDK in development mode with docs dependencies
cd "$PYTHON_SDK_DIR"
pip install -e ".[dev]" --quiet
pip install -r "$ROOT_DIR/config/sphinx/requirements.txt" --quiet

# Check if SDK has existing Sphinx docs directory
if [ -d "$PYTHON_SDK_DIR/docs" ]; then
  # Use existing Sphinx configuration from SDK
  cp "$ROOT_DIR/config/sphinx/conf.py" "$PYTHON_SDK_DIR/docs/conf.py.bak" 2>/dev/null || true

  # Merge configurations if needed
  sphinx-build -b html "$PYTHON_SDK_DIR/docs" "$OUTPUT_DIR"
else
  # Create minimal Sphinx structure
  mkdir -p "$PYTHON_SDK_DIR/docs"

  # Copy our Sphinx config
  cp "$ROOT_DIR/config/sphinx/conf.py" "$PYTHON_SDK_DIR/docs/conf.py"

  # Create index.rst
  cat > "$PYTHON_SDK_DIR/docs/index.rst" << 'EOF'
Griddy Python SDK
=================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   modules

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
EOF

  # Generate API documentation
  sphinx-apidoc -o "$PYTHON_SDK_DIR/docs" "$PYTHON_SDK_DIR/src/griddy" -f -e

  # Build HTML
  sphinx-build -b html "$PYTHON_SDK_DIR/docs" "$OUTPUT_DIR"
fi

echo "Python SDK docs built successfully"