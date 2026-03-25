#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Usage:
#   hex_to_rgb <<< "#784dFF" # rgb(120,77,255)
function hex_to_rgb {
  read -r hex _
  hex=${hex/#\#/}
  printf "rgb(%d,%d,%d)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
