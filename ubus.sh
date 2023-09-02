#!/bin/sh
[ "$REQUEST_METHOD" != "POST" ] && printf 'Status: 405\r\n\r\n' && exit

access() {
  local sid=$1
  local obj=$2
  local fun=$3

  local req=$(printf '{ "ubus_rpc_session": "%s", "scope": "ubus", "object": "%s", "function": "%s" }' "$sid" "$obj" "$fun")
  local res=$(ubus call session access "$req" | jsonfilter -e '@.access')

  [ "$res" = "true" ]
}

error() {
  local code=$1
  local mesg=$2

  printf '{ "jsonrpc": "2.0", "id": "%s", "error": { "code": %d, "message": "%s" } }'  \
    "${RPC_ID:-null}" "$code" "$mesg"

  exit 1
}

process() {
  local request=$1

  # - use `VAR=expr` notation to let it create shell compatible export statements
  # - eval result to import variables
  eval $(jsonfilter -s "$request" \
    -e 'RPC_ID=@.id' \
    -e 'RPC_VERSION=@.jsonrpc' \
    -e 'RPC_METHOD=@.method' \
    -e 'RPC_SESSION_ARG=@.params[3].ubus_rpc_session' \
    -e 'UBUS_SID=@.params[0]' \
    -e 'UBUS_SERVICE=@.params[1]' \
    -e 'UBUS_CMD=@.params[2]')

  # verify JSON-RPC framing
  if [ -z "$RPC_ID" ] || [ "$RPC_VERSION" != "2.0" ]; then
    error -32600 "Invalid request"
  fi

  # reject invalid values to prevent shell injection
  case "$RPC_ID$UBUS_SID$UBUS_SERVICE$UBUS_CMD" in
    *[^a-zA-Z0-9_.-]*) error -32600 "Invalid request" ;;
  esac

  case "$RPC_METHOD" in
    call)
      UBUS_PAYLOAD=$(jsonfilter -s "$request" -e '@.params[3]')

      # ensure that payload is a dictionary or empty
      case "$UBUS_PAYLOAD" in
        ""|{*}) : ;;
        *) error -32602 "Invalid parameters" ;;
      esac

      # merge ubus_rpc_session parameter
      if [ -z "$UBUS_PAYLOAD" ] || [ "$UBUS_PAYLOAD" = "{ }" ]; then
        UBUS_PAYLOAD=$(printf '{ "ubus_rpc_session": "%s" }' "$UBUS_SID")
      else
        UBUS_PAYLOAD=$(printf '{ "ubus_rpc_session": "%s", %s' "$UBUS_SID" "${UBUS_PAYLOAD#\{ }")
      fi

      # reject requests with embedded ubus_rpc_session
      if [ -n "$RPC_SESSION_ARG" ]; then
        error -32602 "Invalid parameters"
      fi

      # check access
      if ! access "$UBUS_SID" "$UBUS_SERVICE" "$UBUS_CMD"; then
        error -32002 "Access denied"
      fi

      ubus_reply=$(ubus call "$UBUS_SERVICE" "$UBUS_CMD" "$UBUS_PAYLOAD")
      ubus_status=$?

      printf '{ "jsonrpc": "2.0", "id": "%s", "result": [ %d, %s ] }' \
        "$RPC_ID" "$ubus_status" "${ubus_reply:-null}"
    ;;
    list)
      RPC_PARAMS=$(jsonfilter -s "$request" -e '@.params')

      # ensure that payload is an array or empty
      case "${RPC_PARAMS:-[ ]}" in
        \[*\]) : ;;
        *) error -32602 "Invalid parameters" ;;
      esac

      # empty payload should result in list of services
      if [ "${RPC_PARAMS:-[ ]}" = "[ ]" ]; then
        services=''

        for service in $(ubus list); do
          services="${services:+$services, }\"$service\""
        done

        printf '{ "jsonrpc": "2.0", "id": "%s", "result": [ %s ] }' \
          "$RPC_ID" "$services"

      # list of services should result in { service => { method => signature } } replies
      else
        signatures=''

        eval $(jsonfilter -s "$RPC_PARAMS" -e 'indexes=@')

        for i in $indexes; do
          service=$(jsonfilter -s "$RPC_PARAMS" -e "@[$i]")
          signature=''

          IFS=$'\n\t'
          for line in $(ubus -v list "$service" | tail -n +2); do
            signature="${signature:+$signature, }$line"
          done
          IFS=$' \n\t'

          signatures="${signatures:+$signatures, }\"$service\": { $signature }"
        done

        printf '{ "jsonrpc": "2.0", "id": "%s", "result": { %s } }' \
          "$RPC_ID" "$signatures"
      fi
    ;;
    *)
      error -32601 "Method not found"
    ;;
  esac
}

# - read body from stdin (either an object or array)
# - process each item if it is an array
body=$(cat)
type=$(jsonfilter -s "$body" -t '@')

printf 'Content-Type: application/json\r\n\r\n'

if [ "$type" = "array" ]; then
  first=true
  printf '['
  jsonfilter -s "$body" -e '@.*' | while read request ; do
    # join response with ',' and the first should be omitted
    if ! $first; then
      printf ','
    else
      first=false
    fi
    # process each request
    process "$request"
  done
  printf ']'
else
  process "$body"
fi
