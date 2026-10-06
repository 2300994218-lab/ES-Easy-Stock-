#!/usr/bin/env sh
# Ensure the writable data directory belongs to the unprivileged runtime user.
# On volume-mounted directories the ownership cannot be known at build time, so
# fix it up here.
chown -R nobody:nogroup "$DATA_DIR" 2>/dev/null || true
chown -R nobody:nogroup "$HOME" 2>/dev/null || true

exec tini -- "$@"