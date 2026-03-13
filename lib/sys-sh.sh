#!/usr/bin/bash
# termux only
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

function sys-sh {
  # Prefer adb (single nmap, then immediate)
  if ADB_DEV=$(adbc 2> /dev/null); then
    adb -s "${ADB_DEV}" shell "${@}"
    return
  fi

  # fallback to Shizuku
  if ! command -v rish > /dev/null 2>&1; then
    echo "sys-sh: no rish, no adb :/" >&2
    return 1
  fi

  local args=("${@:2}")
  rish -c "${1} ${args[*]@Q}"
}
