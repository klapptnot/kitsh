#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Usage:
#   xml_escape <<< 'escape & "quote"?' # escape &amp; &quot;quote&quot;&#63;
function xml_escape {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"

  local encoded=""
  for ((i = 0; i < ${#input}; i++)); do
    case ${input:i:1} in
      \') encoded+="&apos;" ;;
      \") encoded+="&quot;" ;;
      \&) encoded+="&amp;" ;;
      \<) encoded+="&lt;" ;;
      \>) encoded+="&gt;" ;;
      *)
        if [[ "${input:i:1}" =~ [[:punct:]] ]]; then
          printf -v encoded "%s&#%d;" "${encoded}" "'${input:i:1}"
        else
          encoded+="${input:i:1}"
        fi
        ;;
    esac
  done
  printf '%s' "${encoded}"
}
