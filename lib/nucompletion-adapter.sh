#!/usr/bin/bash

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025-present Klapptnot

function nucompletion-adapter {
  local s='' res=() o="${IFS}"
  while IFS=$'\t\n' read -r value desc; do
    value="${value@Q}"            # escape string
    value="${value/#\$/}"         # remove leading $ (if found)
    value="${value:1:-1}"         # remove '...' quotes added
    value="${value//\'\\\'\'/\'}" # remove '\'' no need to escape
    value="${value//\"/\\\"}"     # escape "
    desc="${desc@Q}"
    desc="${desc/#\$/}"
    desc="${desc:1:-1}"
    desc="${desc//\'\\\'\'/\'}"
    desc="${desc//\"/\\\"}"
    printf -v s '{"value":"%s", "display": "%s", "description": "%s", "style": {"fg": "green"}}' "${value}" "${value}" "${desc}"
    res+=("${s}")
  done
  IFS=',' s="${res[*]}"
  IFS="${o}"
  printf '[%s]' "${s}"
}
