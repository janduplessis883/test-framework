#!/usr/bin/env sh
set -eu

NODE="/Users/janduplessis/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node"

PATH="$(dirname "$NODE"):$PATH" "$NODE" ./node_modules/vite/bin/vite.js --host 127.0.0.1 "$@"
