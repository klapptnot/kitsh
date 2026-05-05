#!/usr/bin/bash
# 🔗 https://github.com/klapptnot/bash.sh
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

# Function to easy generate (random) strings
# Usage: rsum [options]
#   -l, --length  Opt<int> default: 16
#   -c, --chars   Opt<str> default: "a-zA-Z0-9"
#   -s, --sep     Opt<str> default: ""
#   -t, --times   Opt<int> default: 0
#   -b, --break   (flag)   default: false
#
# This: rsum -l 5 -c '0-9' -s '-' -t 5 -b
# Prints something like: 28942-11609-47543-66540-15565
function rsum {
  [ "${#}" -eq 0 ] && {
    tr -dc "a-zA-Z0-9" < /dev/urandom 2> >(sed 's/^tr:/rsum:/' >&2) | head -c "16"
    return
  }

  local break_line=false
  local length="16"
  local charset="a-zA-Z0-9"
  local sep=""
  local times=""
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -l | -l* | --length)
        if [[ "${1}" == '--length' ]]; then
          length=${2}
          shift 1
        elif [ -n "${1#-l}" ]; then
          length=${1#-l}
        fi
        ;;
      -c | --chars)
        if [ -n "${2}" ]; then
          charset=${2}
          shift 1
        fi
        ;;
      -s | --sep)
        if [ -n "${2}" ]; then
          sep=${2}
          shift 1
        fi
        ;;
      -t | -t* | --times)
        if [[ "${1}" == '--times' ]]; then
          times=${2}
          shift 1
        elif [ -n "${1#-t}" ]; then
          times=${1#-t}
        fi
        ;;
      -b | --break)
        break_line=true
        ;;
    esac
    shift 1
  done

  [[ ${times} =~ ^[0-9]+$ ]] && {
    local esep="${sep@Q}"
    [ "${esep:0:1}" == '$' ] && esep="${esep:2:-1}"
    esep="${esep:1:-1}"
    tr -dc "${charset}" < /dev/urandom 2> >(sed 's/^tr:/rsum:/' >&2) | head -c "$((length * times))" | sed "s/\(.\{1,${length}\}\)/\1${esep}/g;s/${esep}$//"
    ${break_line} && echo '' 2> /dev/null
    return
  }

  tr -dc "${charset}" < /dev/urandom 2> >(sed 's/^tr:/rsum:/' >&2) | head -c "${length}"
  ${break_line} && echo '' 2> /dev/null
  return 0
}
