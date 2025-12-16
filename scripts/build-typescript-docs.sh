echo "Working on TypeScript documentation..."

echo "$TYPESCRIPT_SDK_DIR"
cd "$TYPESCRIPT_SDK_DIR"
ls -lah
npm ci

TS_CONFIG="$ROOT_DIR/config/typedoc/tsconfig.json"
TYPEDOC_CONFIG="$ROOT_DIR/config/typedoc/typedoc.json"

echo "TypeScript config file: $TS_CONFIG"
echo "Typedoc config file: $TYPEDOC_CONFIG"

npx typedoc --tsconfig "$TS_CONFIG" --options "$TYPEDOC_CONFIG"




