#!/bin/sh
body=$(cat)

UBUS_METHOD=$(echo -n "$body" | jsonfilter -e '@.method')
UBUS_SID=$(echo -n "$body" | jsonfilter -e '@.params[0]')
UBUS_SERVICE=$(echo -n "$body" | jsonfilter -e '@.params[1]')
UBUS_CMD=$(echo -n "$body" | jsonfilter -e '@.params[2]')
UBUS_PAYLOAD=$(echo -n "$body" | jsonfilter -e '@.params[3]')
UBUS_RESP=$(ubus "$UBUS_METHOD" "$UBUS_SERVICE" "$UBUS_CMD" "$UBUS_PAYLOAD")
UBUS_ERR=$?
if [ ${UBUS_ERR} -eq 0 ]; then
  printf 'Content-Type: application/json\r\n\r\n{"result":[0,%s]}' "$UBUS_RESP"
else
  printf 'Content-Type: application/json\r\n\r\n{"error":{"code":-32603,"message":"Internal JSON-RPC error."}}'
fi
