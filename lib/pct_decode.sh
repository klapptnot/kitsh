#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Usage:
#   pct_decode <<< "I%20%F0%9F%92%9C%20bash" # I 💜 bash
function pct_decode {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"
  printf "%b" "${input//\%/\\x}"
}
