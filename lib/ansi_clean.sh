#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Usage:
#  ansi_clean <<< $'\033[38;5;12mHellow\033[0GHello World!\033[0m' # 'Hello World'
function ansi_clean {
  # Remove ANSI escape sequences
  sed -E '
    s/^.*\x1b\[0?[kK]//g;s/^.*\x1b\[0?[gG]//g; # Remove overwritten/cleaned lines
    s/\x1b\[([0-9]*;)*[A-Za-z]//g;             # Basic ANSI sequences
    s/\x1b\[[\(\)#?]?([0-9];?)*[A-Za-z]//g;    # Extended ANSI sequences
    s/\x1b[@-_][0-9;]*[0-9A-Za-z]*//g;         # Any unhandled sequences
  '
}
