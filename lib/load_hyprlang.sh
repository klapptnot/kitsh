#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

function load_hyprlang {
  [ -z "${1}" ] && return 1
  local config_file="${1}"
  shift 1

  [[ ! -f "${config_file}" ]] && return 1
  local val_r='("((\\"|[^"])*?)"|'\''((\\'\''|[^'\''])*?)'\''|(-?[0-9]+|true|false)|\$([\*A-Za-z_.][A-Za-z0-9_.]+))'
  local kev_r="\s*([\*A-Za-z_.][A-Za-z0-9_.]+)\s*=\s*${val_r}\s*"
  local kvc_r='\$([\*A-Za-z_.][A-Za-z0-9_.]+)\s*=\s*'"${val_r}"
  local obj_r="\{((\s*([\*A-Za-z_.][A-Za-z0-9_.]+)\s*=\s*${val_r}\s*)+)\}"

  local f="$(< "${config_file}")"
  local key val obj reg

  declare -A vars
  while [[ ${f} =~ ${kvc_r} ]]; do
    local key="${BASH_REMATCH[1]}"
    local val="${BASH_REMATCH[3]:-${BASH_REMATCH[5]:-${BASH_REMATCH[7]}}}"
    vars[${key}]="${val}"
    f="${f//"${BASH_REMATCH[0]//\\/\\\\}"/}"
  done

  for o in "${@}"; do
    reg="${o} ${obj_r}"

    [[ "${f}" =~ ${reg} ]] || continue
    local obj="${BASH_REMATCH[1]}"
    declare -n config_var="${o}"

    # Escapes in string must be escaped
    f="${f/"${BASH_REMATCH[0]//\\/\\\\}"/}"
    while [[ ${obj} =~ ${kev_r} ]]; do
      local key="${BASH_REMATCH[1]}"
      if [ -n "${BASH_REMATCH[8]}" ]; then
        config_var[${key}]="${vars[${BASH_REMATCH[8]}]}"
      else
        local val="${BASH_REMATCH[3]:-${BASH_REMATCH[5]:-${BASH_REMATCH[7]}}}"
        config_var[${key}]="${val}"
      fi
      obj="${obj//"${BASH_REMATCH[0]//\\/\\\\}"/}"
    done
    unset key val obj
  done

  return 0
}
