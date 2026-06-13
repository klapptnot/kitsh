#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Usage
#   rgb_to_hex <<< "rgb(120,77,255)" # #784dFF
function rgb_to_hex {
  read -r rgb
  local rgb="${rgb:4:-1}"
  printf '#%02x%02x%02x' ${rgb//,/\ } 2> /dev/null
}
