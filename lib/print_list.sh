#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Print passed strings horizontally aligned
# Usage:
#   print_list [strings]
# Example:
#   $ print_list Hello darkness my old friend I\'ve come to talk with you again
#   Hello     darkness  my        old
#   friend    I've      come      to
#   talk      with      you       again
function print_list {
  read -r _ cols < <(stty size)
  local maxl=0
  for i in "${@}"; do
    ((${#i} > maxl)) && maxl="${#i}"
  done
  local idl=$((maxl + 2))
  local iil=$((cols / idl))
  local i=1
  for it in "${@}"; do
    printf "%-${idl}s" "${it}"
    (((i % iil) == 0)) && printf '\n'
    ((i++))
  done
  printf '\n'
}
