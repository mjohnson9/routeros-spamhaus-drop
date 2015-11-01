#!/bin/dash

set -e

ssh "$1" '/ip firewall address-list export' | grep -F 'list=spamhaus-drop' | grep -oE 'address=((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])(/([1-2]?[0-9]|3[0-2]))?' | cut -d '=' -f2
