#!/bin/sh

set -e

die() {
	echo >&2 "$@"
	exit 1
}

[ "$#" -eq 1 ] || die "Usage: $0 <SSH address of router>"

# Create printed address list on the router
ssh "$1" "/ip firewall address-list print file=spamhaus-drop where list=spamhaus-drop"

# Create a temporary file to store the list on our end
TMPFILE="$(mktemp)"
trap "rm -f ${TMPFILE}" EXIT

# Download print list from the router
scp "$1:/spamhaus-drop.txt" "${TMPFILE}"
# Remove file in the background
ssh "$1" "/file remove spamhaus-drop.txt" &

# Extract the IP addresses from the print list and print it on stdout
cat "${TMPFILE}" | grep -Fv ';;;' | grep -Fv '#' | grep -oE '((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])(\/(3[0-2]|[1-2][0-9]|[0-9]))?' | tr -d "\r"
