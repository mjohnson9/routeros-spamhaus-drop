#!/bin/dash

set -e

URL="https://www.spamhaus.org/drop/$1.lasso"

curl -s -L -o - "${URL}" | sed 's/[[:blank:]]*;.*$//g' | grep -v '^$'
