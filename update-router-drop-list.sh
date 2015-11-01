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

{ "${SCRIPT_DIR}/get-spamhaus-list.sh" drop; "${SCRIPT_DIR}/get-spamhaus-list.sh" edrop; } | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u > spamhaus.txt
"${SCRIPT_DIR}/get-router-address-list.sh" "${ROUTER}" | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u > router.txt

re2='^([-+])([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?)$'

current_date="$(date --utc --rfc-3339=seconds)"

diff -wU0 router.txt spamhaus.txt | while read dl; do
	if [[ $dl =~ $re2 ]]; then
		case "${BASH_REMATCH[1]}" in
			+)
				#echo "New IP address: ${BASH_REMATCH[2]}"
				echo "/ip firewall address-list add list=spamhaus-drop comment=\"${current_date}\" address=${BASH_REMATCH[2]}" >> script.txt
				;;
			-)
				#echo "IP address removed: ${BASH_REMATCH[2]}"
				echo "/ip firewall address-list remove [find list=spamhaus-drop address=${BASH_REMATCH[2]}]" >> script.txt
				;;
		esac
	fi
done

ssh "${ROUTER}" < script.txt
