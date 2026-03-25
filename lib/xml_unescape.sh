#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Usage:
#   xml_unescape <<< 'escape &amp; &quot;quote&quot;&#63;' # escape & "quote"?
function xml_unescape {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"

  input="${input//&apos;/\'}"
  input="${input//&quot;/\"}"
  input="${input//&amp;/\&}"
  input="${input//&lt;/\<}"
  input="${input//&gt;/\>}"

  while [[ "${input}" =~ \&#([0-9]+)\; ]]; do
    printf -v cv '%08x' "${BASH_REMATCH[1]}"
    input="${input//${BASH_REMATCH[0]}/"\\U${cv}"}"
  done
  printf "%b" "${input}"
}
