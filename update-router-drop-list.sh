#!/bin/sh

set -e

die() {
	echo >&2 "$@"
	exit 1
}

[ "$#" -eq 1 ] || die "Usage: $0 <SSH address of router>"

# Router's SSH address
ROUTER="$1"

# This script's directory
SCRIPT_DIR="$( pwd )"

# Temporary directory for storing our working files
TMPDIR="$(mktemp -d)"
trap "rm -rf ${TMPDIR}" EXIT

# Change into our temporary directory
cd "${TMPDIR}"

# Download the sanitized drop list from Spamhaus
{ "${SCRIPT_DIR}/get-spamhaus-list.sh" drop; "${SCRIPT_DIR}/get-spamhaus-list.sh" edrop; } | sort -u > spamhaus.txt &
# Download the list from the router
"${SCRIPT_DIR}/get-router-address-list.sh" "${ROUTER}" | sort -u > router.txt &

# Wait for the downloads to finish
wait

# Save the current time for the address list
current_date="$(date)"

# Find address that are in router.txt but not spamhaus.txt
comm -23 router.txt spamhaus.txt | while read dl; do
	echo "/ip firewall address-list remove [find list=spamhaus-drop address=${dl}]" >> script.txt
done

# Find addresses that are in spamhaus.txt but not router.txt
comm -13 router.txt spamhaus.txt | while read dl; do
	echo "/ip firewall address-list add list=spamhaus-drop comment=\"${current_date}\" address=${dl}" >> script.txt
done

if [ -e script.txt ]; then
	# Connect to the router to apply changes
	ssh "${ROUTER}" < script.txt
	echo "Made $(wc -l script.txt) changes."
else
	echo "Made 0 changes."
fi
