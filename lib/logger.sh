#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

declare -gra LOGGER_LOG_COLORS=(
  ''
  '\x1b[30m\x1b[41m'
  '\x1b[31m'
  '\x1b[33m'
  '\x1b[34m'
  '\x1b[32m'
)
declare -gra LOGGER_LEVEL_NAMES=(
  'OFF'   # 0
  'CRIT'  # 1
  'ERROR' # 2
  'WARN'  # 3
  'INFO'  # 4
  'DEBUG' # 5
)
declare -grA LOGGER_LEVEL_NUMS=(
  ['o']=0
  ['c']=1
  ['e']=2
  ['w']=3
  ['i']=4
  ['d']=5
)

# Normalize log level from env once at load time.
# Accepts: 0-5, o/c/e/w/i/d, or off/crit/error/warn/info/debug
# Precedence: LOGGER_LEVEL > LOG_LEVEL > default (info)
function log::setup {
  local raw="${1:-${LOGGER_LEVEL:-${LOG_LEVEL:-i}}}"
  raw="${raw,,}"

  if [[ "${raw}" =~ ^[0-5]$ ]]; then
    LOGGER_EFFECTIVE_LEVEL="${raw}"
  elif [[ -n "${raw}" && -n "${LOGGER_LEVEL_NUMS[${raw:0:1}]}" ]]; then
    LOGGER_EFFECTIVE_LEVEL="${LOGGER_LEVEL_NUMS[${raw:0:1}]}"
  fi

  declare -gri LOGGER_EFFECTIVE_LEVEL="${LOGGER_EFFECTIVE_LEVEL:-4}"
}

# Print (or not) to output info based on the LOGGER_LEVEL env var
# LOGGER_LEVEL is `i` by default
# Usage:
#   log <level> <fmt> [args...]
function log {
  [[ -z "${1}" ]] && return
  [[ -z "${LOGGER_EFFECTIVE_LEVEL+x}" ]] && log::setup

  : "${1:0:1}"
  local -ri level="${LOGGER_LEVEL_NUMS[${_,,}]:-0}"
  ((0 == LOGGER_EFFECTIVE_LEVEL || level > LOGGER_EFFECTIVE_LEVEL)) && return

  # shellcheck disable=SC2059
  printf -v message "${2}" "${@:3}"

  local color="${LOGGER_LOG_COLORS[level]}"
  if ((${#1} > 1)); then
    printf '%b[%(%F %T)T] %5s: %s\x1b[0m\n' "${color}" -1 "${LOGGER_LEVEL_NAMES[level]}" "${message}" &> /dev/stderr
  else
    printf '%b%s\x1b[0m\n' "${color}" "${message}" &> /dev/stderr
  fi
}
