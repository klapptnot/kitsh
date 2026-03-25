#!/usr/bin/bash
# 🔗 https://github.com/klapptnot/bash.sh
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Usage:
#   pct_encode <<< "I 💜 bash" # I%20%F0%9F%92%9C%20bash
function pct_encode {
  mapfile all < /dev/stdin
  printf -v input '%s' "${all[@]}"

  local encoded=""
  local LC_ALL="C" # support unicode loop bytes
  for ((i = 0; i < ${#input}; i++)); do
    # Python's urllib.parse.quote leaves `/` without encoding
    if [[ "${input:i:1}" =~ ^[a-zA-Z0-9.~_-]$ ]]; then
      printf -v encoded "%s%s" "${encoded}" "${input:i:1}"
    else
      printf -v encoded "%s%%%02X" "${encoded}" "'${input:i:1}"
    fi
  done
  printf '%s' "${encoded}"
}
