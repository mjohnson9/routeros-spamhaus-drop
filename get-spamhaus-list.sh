#!/bin/sh

set -e

[ "$#" -eq 1 ] || die "Usage: $0 <drop list type (drop, edrop)>"

# URL for drop list
URL="https://www.spamhaus.org/drop/$1.lasso"

# Download list, remove comments, and convert line endings to Unix
curl -s -L -o - "${URL}" | sed 's/[[:blank:]]*;.*$//g' | grep -v '^$' | tr -d "\r"
