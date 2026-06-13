#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# Display a nice functional progress bar
# Usage: rsum [options]
#   -l, --label     Opt<str> default: ""    -> bar label
#   -c, --char      Opt<str> default: "•"   -> char displayed
#   -k, --keep      (flag)   default: false -> keep bar when done
#   -L, --left      (flag)   default: false -> show progress left
#   -C, --centered  (flag)   default: false -> center the bar
#   -n, --linefeed  (flag)   default: false -> add \n when done
#
# Function must print '[::pb.draw::] <percentage>' to update bar
# Any other (stdin) input will be repeated
# Example:
# for ((i=0;i<=100;i++)); do
#   (((i % 5) == 0)) && printf 'Multiple of 5!\n'
#   printf '[::pb.draw::] %d\n' "${i}"
# done | pbar -l 'Test label'
function pbar {
  [ "${#}" -eq 0 ] && return

  local SHOW_LEFT=false
  local CENTERED=false
  local REMOVE_BAR=true
  local LINEBREAK=false
  local PROGRESS_CHAR="•" # █
  local BAR_LABEL=""
  local BAR_COLOR='38;5;99'
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -l | --label)
        BAR_LABEL="${2}"
        shift 2
        ;;
      -c | --char)
        [ "${#2}" -eq 1 ] && PROGRESS_CHAR="${2}"
        shift 2
        ;;
      -L | --left)
        SHOW_LEFT=true
        shift 1
        ;;
      -C | --centered)
        CENTERED=true
        shift 1
        ;;
      -k | --keep)
        REMOVE_BAR=false
        shift 1
        ;;
      -n | --linefeed)
        LINEBREAK=true
        shift 1
        ;;
      *)
        shift 1
        ;;
    esac
  done

  local BAR_SIZES=(100 50 20 10)

  local BAR_WIDTH
  local LAST_CALCULATED_WIDTH
  local LAST_COLMS
  local SHOW_LABEL="${BAR_LABEL}"
  function __resize_bar {
    read -r COLUMNS < <(tput cols)
    for w in "${BAR_SIZES[@]}"; do
      (((${#BAR_LABEL} + w) + 7 <= COLUMNS)) && {
        ((w < LAST_CALCULATED_WIDTH)) && printf '\x1b[1A' # go up one line
        LAST_CALCULATED_WIDTH="${w}"
        LAST_COLMS="${COLUMNS}"
        break
      }
      printf '\x1b[0J' # clear below line, erasing wrapped line
    done
    if ${CENTERED}; then
      ((margin = (LAST_COLMS - (LAST_CALCULATED_WIDTH + 7)) / 2))
      ((margin = margin % 2 != 0 ? margin - 1 : margin))

      printf -v SHOW_LABEL "%-${margin}s" "${BAR_LABEL}"
    fi
  }
  __resize_bar

  trap '__resize_bar' SIGWINCH
  local LAST_LINE=""
  local CURRENT_STEP=""
  local BAR_PROGRESS_CHARS=""

  while read -r CURRENT_STEP; do
    if [ -z "${CURRENT_STEP}" ] || [[ "${CURRENT_STEP}" != "[::pb.draw::] "* ]]; then
      printf '\x1b[0K\x1b[0G%s\n%s' "${CURRENT_STEP}" "${LAST_LINE}"
      continue
    fi
    BAR_WIDTH="${LAST_CALCULATED_WIDTH}"

    CURRENT_STEP="${CURRENT_STEP:14:${#CURRENT_STEP}}"
    ((CURRENT_STEP <= LAST_STEP)) && continue

    local DISPLAY_STEP_NUM=${CURRENT_STEP}
    ${SHOW_LEFT} && DISPLAY_STEP_NUM=$(((BAR_WIDTH * (100 / BAR_WIDTH)) - CURRENT_STEP))

    ((BAR_PROGRESS = CURRENT_STEP / (100 / BAR_WIDTH)))
    ((PAD_SPC = BAR_WIDTH - BAR_PROGRESS))
    read -r N < <(seq -s ' ' 1 ${BAR_PROGRESS})
    # shellcheck disable=SC2086
    printf -v BAR_PROGRESS_CHARS "${PROGRESS_CHAR}%.0s" ${N}

    LAST_STEP=${CURRENT_STEP}

    printf -v LAST_LINE \
      "\x1b[0K%s[\x1b[${BAR_COLOR}m%s\x1b[0m%${PAD_SPC}s] %4s\x1b[0G" \
      "${SHOW_LABEL}" "${BAR_PROGRESS_CHARS}" "" "${DISPLAY_STEP_NUM}%"

    printf '%s' "${LAST_LINE}"

    ((CURRENT_STEP < 100)) && continue
    break
  done
  trap - SIGWINCH

  ${REMOVE_BAR} && printf '\x1b[0K\x1b[0G'
  ${LINEBREAK} && printf "\n"
  return 0
}
