#!/bin/bash
service mysql start
trap "service mysql stop" EXIT
for f in "$@"; do
	echo -n "Importing $f... "
	cat "$f" | mysql -u "root" -p"$MYSQLROOTPW" --default-character-set=utf8
	ret=$?
	if [ $ret == 0 ]; then
		echo "done"
	else
		exit $ret
	fi
done
