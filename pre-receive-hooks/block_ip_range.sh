#!/usr/bin/env bash

#
# Pre-receive hook that will reject all pushes received from IP addresses
# between `IP_LOW` and `IP_HIGH`
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#
# NOTE: Use at your own risk!

function ip2dec {
  # see http://stackoverflow.com/a/10768196/1525223
  local a b c d ip=$@
  IFS=. read -r a b c d <<< "$ip"
  echo "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

# define lower IP limit
IP_LOW="0.0.0.0"
IP_LOW_INT=$(ip2dec "${IP_LOW}")

# define upper IP limit
IP_HIGH="255.255.255.255"
IP_HIGH_INT=$(ip2dec "${IP_HIGH}")

# get IP from pre-receive hook variable
IP_IN="${GITHUB_USER_IP}"
IP_INT=$(ip2dec "${IP_IN}")

# reject push if `IP_IN` is between `IP_LOW` and IP_HIGH
if [ "${IP_INT}" -ge "${IP_LOW_INT}" ] && [ "${IP_INT}" -le "${IP_HIGH_INT}" ]; then
  echo "Hello there! We have restricted pushes from your IP (${IP_IN}) address. Please see Dave in IT to discuss alternatives."
  exit 1
fi

exit 0
