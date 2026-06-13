#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

function load_conf {
  [ -z "${1}" ] && return 1
  local config_file="${2}"

  [[ ! -f "${config_file}" ]] && return 1
  declare -n config_var="${1}"

  local key val
  while IFS=':' read -r key val; do
    [[ -z "${key}" || "${key}" =~ ^[[:space:]]*# ]] && continue

    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"

    config_var["${key}"]="${val}"
  done < "${config_file}"

  return 0
}
