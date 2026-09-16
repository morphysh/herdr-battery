#!/bin/sh
# Opens the battery details popup through the running Herdr server.
HERDR="${HERDR_BIN_PATH:-herdr}"
exec "$HERDR" plugin pane open --plugin rock.battery --entrypoint details
