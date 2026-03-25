#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Usage:
#  xml_escape_all <<< "escape" # &#101;&#115;&#99;&#97;&#112;&#101;
function xml_escape_all {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"
  for ((i = 0; i < ${#input}; i++)); do
    printf -v encoded "%s&#%d;" "${encoded}" "'${input:i:1}"
  done
  printf '%s' "${encoded}"
}
