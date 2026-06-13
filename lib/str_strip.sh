#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Strip leading or trailing [:space:] from stdin input
# Usage:
#    str_strip start <<< "  Hi! UwU~  " # "Hi! UwU~  "
#    str_strip end   <<< "  Hi! UwU~  " # "  Hi! UwU~"
#    str_strip       <<< "  Hi! UwU~  " # "Hi! UwU~"
function str_strip {
  local s="$(< /dev/stdin)"
  [ "${1}" != "start" ] && s="${s%"${s##*[![:space:]\n]}"}"
  [ "${1}" != "end" ] && s="${s#"${s%%[![:space:]\n]*}"}"
  printf "%s" "${s}"
}
