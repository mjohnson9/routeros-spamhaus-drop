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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Temporary directory for storing our working files
TMPDIR="$(mktemp -d)"
trap "rm -rf ${TMPDIR}" EXIT

# Change into our temporary directory
cd "${TMPDIR}"

# Download the sanitized drop list from Spamhaus
echo "Downloading Spamhaus DROP list..."
{ "${SCRIPT_DIR}/get-spamhaus-list.sh" drop; "${SCRIPT_DIR}/get-spamhaus-list.sh" edrop; } | sort -u > spamhaus.txt &
# Download the list from the router
echo "Retrieving drop list from router..."
"${SCRIPT_DIR}/get-router-address-list.sh" "${ROUTER}" | sort -u > router.txt &

# Wait for the downloads to finish
wait

echo "Done!"

# Save the current time for the address list
current_date="$(date --utc --iso-8601=seconds)"

# Find address that are in router.txt but not spamhaus.txt
comm -23 router.txt spamhaus.txt | while read dl; do
	echo "/ip firewall address-list remove [find list=spamhaus-drop address=${dl}]" >> script.txt
done

# Find addresses that are in spamhaus.txt but not router.txt
comm -13 router.txt spamhaus.txt | while read dl; do
	echo "/ip firewall address-list add list=spamhaus-drop comment=\"${current_date}\" address=${dl}" >> script.txt
	cidr_regex="$(echo -n "${dl}" | python2 "${SCRIPT_DIR}/cidr-to-regex.py")"
	echo "cidr_regex: ${cidr_regex}"
	echo "/ip firewall connection remove [/ip firewall connection find where dst-address~\"${cidr_regex}\"]" >> script.txt
done

if [ -e script.txt ]; then
	echo "Updating..."
	# Connect to the router to apply changes
	ssh "${ROUTER}" < script.txt
	echo "Made $(wc -l script.txt | cut -d' ' -f1) changes."
else
	echo "Already up-to-date."
fi
