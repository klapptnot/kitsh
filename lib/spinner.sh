#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

declare -g ___SPINNER_TEXT=""
declare -g ___SPINNER_PIPE=""
declare -g ___SPINNER_PID=""

# Initialize spinner - creates FIFO and sets up communication
function spinner.init {
  # Clean up any existing resources first
  spinner.drop

  # Create unique named pipe for communication
  read -r ___SPINNER_PIPE < <(mktemp)

  return 0
}

function spinner.print {
  printf '\x1b[0G\x1b[0J'"${1}\n" "${@:2}"
}

# Start spinner in background - requires init first
function spinner.start {
  [[ -z "${___SPINNER_PIPE}" ]] && {
    echo "Error: spinner.init must be called first" >&2
    return 1
  }

  [[ ! -f "${___SPINNER_PIPE}" ]] && {
    echo "Error: file not found, call spinner.init first" >&2
    return 1
  }

  # Don't start if already running
  [[ -n "${___SPINNER_PID}" ]] && kill -0 "${___SPINNER_PID}" 2> /dev/null && {
    echo "Error: Spinner already running (PID: ${___SPINNER_PID})" >&2
    return 1
  }

  echo "${1:-Loading...}" > "${___SPINNER_PIPE}"
  {
    local __chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local __index=0
    local __total="${#__chars[@]}"
    read -r __rcol < <(od -An -N1 -tu1 /dev/urandom)
    printf '\x1b[?25l'

    while true; do
      read -r -t0.001 __label < "${___SPINNER_PIPE}"

      printf '\x1b[0K%b%s\x1b[0m %s\x1b[0G' "\x1b[38;5;${__rcol}m" "${__chars[__index]}" "${__label}"

      ((__index++))
      ((__index >= __total)) && read -r __rcol < <(od -An -N1 -tu1 /dev/urandom) && __index=0
      sleep 0.015
    done
  } &
  ___SPINNER_PID="${!}"
  return 0
}

# Update spinner text
function spinner.update {
  local new_text="${1:-${___SPINNER_TEXT}}"

  if [[ -n "${___SPINNER_PIPE}" && -f "${___SPINNER_PIPE}" ]]; then
    echo "${new_text}" > "${___SPINNER_PIPE}"
    return 0
  fi

  return 1
}

# Stop spinner (pause) - kills process but keeps resources
function spinner.stop {
  if [[ -n "${___SPINNER_PID}" ]]; then
    kill "${___SPINNER_PID}" &> /dev/null
    wait "${___SPINNER_PID}" 2> /dev/null
    ___SPINNER_PID=""
  fi

  printf '\x1b[?25h\x1b[0G\x1b[0J'
  return 0
}

# Drop spinner - complete cleanup and reset
function spinner.drop {
  # Kill process if running
  if [[ -n "${___SPINNER_PID}" ]]; then
    kill "${___SPINNER_PID}" &> /dev/null
    wait "${___SPINNER_PID}" 2> /dev/null

    # Clean up display
    printf '\x1b[?25h\x1b[0G\x1b[0J'
  fi

  # Remove FIFO
  [[ -n "${___SPINNER_PIPE}" && -f "${___SPINNER_PIPE}" ]] && rm -f "${___SPINNER_PIPE}"

  # Reset all variables
  ___SPINNER_TEXT=""
  ___SPINNER_PIPE=""
  ___SPINNER_PID=""

  return 0
}

# Check if spinner is running
function spinner.is_running {
  [[ -n "${___SPINNER_PID}" ]] && kill -0 "${___SPINNER_PID}" 2> /dev/null
}
