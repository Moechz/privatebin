#!/bin/sh
# ===========================================================================
# PrivateBin entrypoint for a non-root container (TOS 7 requirement).
#
# The upstream image serves the app with nginx on port 80. A non-root
# container cannot bind port 80, so this wrapper serves the same document
# root (/var/www) with PHP's built-in web server on port 8080 and keeps the
# paste storage on the mounted volume (/srv/data).
#
# The web server is started as a *child* instead of being exec'ed into PID 1.
# A process that is PID 1 gets no default signal handling, so `docker stop`
# used to wait out the whole grace period and then SIGKILL the container
# (review finding F3, "service fails to stop cleanly"). The wrapper stays in
# PID 1, forwards SIGTERM/SIGINT to the server and exits 0 once it is gone.
# ===========================================================================
set -e
set -u

DATA=/srv/data
mkdir -p "$DATA" 2>/dev/null || true

if ! ( : > "$DATA/.write-test" ) 2>/dev/null; then
  echo "privatebin: $DATA is not writable by uid $(id -u)" >&2
  exit 1
fi
rm -f "$DATA/.write-test"

# The image ships php as /usr/local/bin/php; older tags used php85.
PHP=php
command -v php85 >/dev/null 2>&1 && PHP=php85

cd /var/www
"$PHP" -S 0.0.0.0:8080 -t /var/www &
server=$!

shutdown=0
on_signal() {
  shutdown=1
  kill -TERM "$server" 2>/dev/null || true
}
trap on_signal TERM INT

status=0
wait "$server" || status=$?

if [ "$shutdown" -eq 1 ]; then
  # give the server a moment to release the socket, then report a clean stop
  n=0
  while kill -0 "$server" 2>/dev/null && [ "$n" -lt 50 ]; do
    sleep 0.1
    n=$((n + 1))
  done
  status=0
fi

exit "$status"
