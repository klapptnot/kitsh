#!/urs/bin/bash
# 🔗 https://github.com/klapptnot/bash.sh
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

include pct_encode.sh

# Genreate a URL param string based on a associative array
# Usage:
#   url_params "<associative_array_name>"
# Example:
# ```bash
#   declare -A params=( [query]="White houses" [tags]="house,white,village" )
#   read -r param_str < <(url_params "params")
#
#   # params_str will contain:
#   # query=White%houses&tags=house%2Cwhite%2Cvillage
# ```
function url_params {
  [ -z "${1}" ] && printf '' && return 1
  declare -n param_map="${1}"

  # local result=""
  local all=()
  for k in "${!param_map[@]}"; do
    read -r encoded_val < <(pct_encode <<< "${param_map[${k}]}")
    all+=("${k}=${encoded_val}")
  done
  local result
  IFS='&' result="${all[*]}"

  printf '%s' "${result}"
}
