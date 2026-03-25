#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Usage:
#  str_escape <<< $'A string\n\tThat will be "escaped"'
function str_escape {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"

  input="${input@Q}"            # escape string
  input="${input/#\$/}"         # remove leading $ (if found)
  input="${input:1:-1}"         # remove '...' quotes added
  input="${input//\'\\\'\'/\'}" # remove '\'' no need to escape
  input="${input//\"/\\\"}"     # escape "
  printf "%s" "${input}"
}
