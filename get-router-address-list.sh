#!/bin/sh

set -e

die() {
	echo >&2 "$@"
	exit 1
}

[ "$#" -eq 1 ] || die "Usage: $0 <SSH address of router>"

#ssh "$1" '/ip firewall address-list export compact' | grep -F 'list=spamhaus-drop' | grep -oE 'address=((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])(/([1-2]?[0-9]|3[0-2]))?' | cut -d '=' -f2

ssh "$1" ':foreach entry in=[/ip firewall address-list find list=spamhaus-drop] do={:put [/ip firewall address-list get $entry address]}'
