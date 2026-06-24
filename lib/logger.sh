#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

declare -gra LOGGER_LEVEL_NAMES=('OFF' 'CRIT' 'ERROR' 'WARN' 'INFO' 'DEBUG')
declare -gra LOGGER_LOG_COLORS=(
  ''
  '\x1b[30m\x1b[41m'
  '\x1b[31m'
  '\x1b[33m'
  '\x1b[34m'
  '\x1b[32m'
)

if [[ "${BASH_SOURCE[0]}" != *"${1}" ]]; then
  readonly _LGGRLEVEL="${1:-4}"
  readonly _LGGRFORMAT="${2:-short}"
else
  readonly _LGGRLEVEL=4
  readonly _LGGRFORMAT="short"
fi

declare -gi LOGGER_EFFECTIVE_LEVEL="${_LGGRLEVEL:-4}"

if [[ -t 1 ]]; then
  if [[ "${_LGGRFORMAT}" == 'long' ]]; then
    function _log::format {
      printf "${LOGGER_LOG_COLORS[${1}]}[%(%F %T)T] %-5s: ${2}\x1b[0m\n" -1 "${LOGGER_LEVEL_NAMES[${1}]}" "${@:3}"
    }
  else
    function _log::format {
      printf "${LOGGER_LOG_COLORS[${1}]}%-5s: ${2}\x1b[0m\n" "${LOGGER_LEVEL_NAMES[${1}]}" "${@:3}"
    }
  fi
else
  function _log::format {
    printf "[%(%F %T)T] %-5s: ${2}\n" -1 "${LOGGER_LEVEL_NAMES[${1}]}" "${@:3}"
  }
fi

function log::crit  { ((LOGGER_EFFECTIVE_LEVEL > 0)) && _log::format 1 "${@}"; } >&2
function log::err   { ((LOGGER_EFFECTIVE_LEVEL > 1)) && _log::format 2 "${@}"; } >&2
function log::warn  { ((LOGGER_EFFECTIVE_LEVEL > 2)) && _log::format 3 "${@}"; } >&2
function log::info  { ((LOGGER_EFFECTIVE_LEVEL > 3)) && _log::format 4 "${@}"; }
function log::debug { ((LOGGER_EFFECTIVE_LEVEL > 4)) && _log::format 5 "${@}"; }
