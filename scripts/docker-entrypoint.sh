
#!/bin/sh
set -e
# allow the container to be started with `--user`
if [ "$(id -u)" = '0' ]; then
	chown -R dogecoin .
	exec gosu dogecoin "$0" "$@"
fi

exec "$@"
