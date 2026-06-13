#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Usage:
#   str_unescape <<< 'A string\n\tThat will be \"unescaped\"'
function str_unescape {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"
  input="${input//\\\"/\"}"
  printf "%s" "${input@E}"
}
