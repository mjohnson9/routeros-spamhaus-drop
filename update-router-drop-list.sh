#!/bin/sh

set -e

die() {
	echo >&2 "$@"
	exit 1
}

[ "$#" -eq 1 ] || die "Usage: $0 <SSH address of router>"

ROUTER="$1"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TMPDIR="$(mktemp -d)"
trap "rm -rf ${TMPDIR}" EXIT

cd "${TMPDIR}"

{ "${SCRIPT_DIR}/get-spamhaus-list.sh" drop; "${SCRIPT_DIR}/get-spamhaus-list.sh" edrop; } | sort -u > spamhaus.txt
"${SCRIPT_DIR}/get-router-address-list.sh" "${ROUTER}" | sort -u > router.txt

dos2unix spamhaus.txt router.txt

current_date="$(date --utc --rfc-3339=seconds)"

comm -23 router.txt spamhaus.txt | while read dl; do
	echo "/ip firewall address-list remove [find list=spamhaus-drop address=${dl}]" >> script.txt
done

comm -13 router.txt spamhaus.txt | while read dl; do
	echo "/ip firewall address-list add list=spamhaus-drop comment=\"${current_date}\" address=${dl}" >> script.txt
done

if [ -e script.txt ]; then
	ssh "${ROUTER}" < script.txt
	echo "Made $(wc -l script.txt) changes."
else
	echo "Made 0 changes."
fi
