#!/bin/dash

set -e

[ "$#" -eq 1 ] || die "Usage: $0 <drop list type (drop, edrop)>"

URL="https://www.spamhaus.org/drop/$1.lasso"

curl -s -L -o - "${URL}" | sed 's/[[:blank:]]*;.*$//g' | grep -v '^$'
