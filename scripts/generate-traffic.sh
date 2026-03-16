#!/bin/bash

# Generate synthetic traffic for the DataFish application.
# Usage:
#   ./scripts/generate-traffic.sh [count]
# Optional env:
#   HOST (default: localhost)
#   SESSION_ID (default: random UUID)
#   SLEEP_MS (default: 200)

set -euo pipefail

HOST="${HOST:-localhost}"
COUNT="${1:-10}"
SESSION_ID="${SESSION_ID:-}"
SLEEP_MS="${SLEEP_MS:-200}"

if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID=$(python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
  )
fi

BASE_URL="http://${HOST}:8080"

get_product_json() {
  curl -s "${BASE_URL}/api/products" || true
}

# Try to extract product id/name from the first product.
PRODUCT_ID="1"
PRODUCT_NAME="Trace Span Clownfish"
PRODUCT_JSON=$(get_product_json)
if [[ -n "$PRODUCT_JSON" ]]; then
  python3 - <<'PY' "$PRODUCT_JSON" >/tmp/datafish_product.txt 2>/dev/null || true
import json, sys
try:
    data = json.loads(sys.argv[1])
    if isinstance(data, list) and data:
        first = data[0]
        pid = first.get('id', 1)
        name = first.get('name', 'Trace Span Clownfish')
        print(f"{pid}|||{name}")
except Exception:
    pass
PY
  if [[ -f /tmp/datafish_product.txt ]]; then
    line=$(cat /tmp/datafish_product.txt | tail -n 1)
    if [[ "$line" == *"|||"* ]]; then
      PRODUCT_ID="${line%%|||*}"
      PRODUCT_NAME="${line##*|||}"
    fi
  fi
fi

payload_cart() {
  cat <<JSON
{"product_id":${PRODUCT_ID},"product_name":"${PRODUCT_NAME}","quantity":1,"price":29.99}
JSON
}

payload_order() {
  cat <<JSON
{"customer_email":"demo@datafish.com","shipping_address":"123 Fish St, Ocean City","items":[{"product_id":${PRODUCT_ID},"product_name":"${PRODUCT_NAME}","quantity":1,"price":29.99}]}
JSON
}

echo "Generating ${COUNT} checkout flows"
echo "Host: ${HOST}"
echo "Session: ${SESSION_ID}"
echo "Product: ${PRODUCT_ID} - ${PRODUCT_NAME}"

for i in $(seq 1 "$COUNT"); do
  echo "--- Run ${i} ---"

  # List products
  curl -s -o /dev/null "${BASE_URL}/api/products" || true

  # Add to cart
  curl -s -o /dev/null -X POST "${BASE_URL}/api/cart?session_id=${SESSION_ID}" \
    -H "Content-Type: application/json" \
    -d "$(payload_cart)" || true

  # Create order
  curl -s -o /dev/null -X POST "${BASE_URL}/api/orders?session_id=${SESSION_ID}" \
    -H "Content-Type: application/json" \
    -d "$(payload_order)" || true

  # Fetch orders
  curl -s -o /dev/null "${BASE_URL}/api/orders?session_id=${SESSION_ID}" || true

  # Small delay to spread traces
  python3 - <<PY
import time
ms = int(${SLEEP_MS})
time.sleep(ms/1000)
PY

done

echo "Done."
