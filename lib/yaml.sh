#!/usr/bin/bash
# Upstream: https://github.com/klapptnot/kitsh
# SPDX-License-Identifier: AGPL-3.0-or-later

# ==============================================================================
# yaml.sh: Zero-dependency, state-machine driven YAML 1.1/1.2 deserializer
#          and serializer implemented entirely in native Bash 4.4+ builtins.
# ==============================================================================
#
#   Written for execution speed in shell environments (e.g., prompt rendering)
#   by eliminating subshell forks (`$(...)`), external utilities (jq/yq/sed/awk).
#   Complex nesting is preserved, allowing fast traversal via namerefs (`declare -n`).
#
#   - Excludes Flow-style syntax, node anchors (`&`), aliases (`*`), and merges (`<<`)
#   - Fits any indent size, but requires uniform/consistent indentation
#   - All scalars as strings, matching shell execution context
#   - No value can start with `__yn`, and root has to start with it
#
#   Signatures prefixed with `!!` may execute `exec false`, other use "${var:?err msg}"
#   For fault-tolerance or recovery blocks, isolate these invocations
#   inside a subshell context: e.g., `( yaml::ensure ... )`
#   Consider this not made for `set -u`, neither `set -e`
#   Uses `set -s extglob`
#
#   !! function yaml::die        - <name:string> <desc:string>
#      function yaml::get_type   - <varname:string>
#      function yaml::check_type - <varname:string> <expected_type:map|list>
#   !! function yaml::get_leaf   - <varname_ref:string> <dot_path:string> <parent_node_ref:string>
#   !! function yaml::ensure     - <expected_type:map|list> <dot_path:string> <parent_node_ref:string>
#      function yaml::escape     - <string_varname:string>
#      function yaml::dump       - <node_name:string> [indentation_spaces:int] [colored:bool]
#   !! function yaml::load       - <varname:string> <file_path:string>
#
# ==============================================================================

declare -Ag __yaml_typereg=()

# !! <name:string> <desc:string>
function yaml::die {
  [[ -t 2 ]] \
    && printf '\x1b[1;31m%s:\x1b[0m %s\n' "${1:?}" "${2:?}" >&2 \
    || printf '%s: %s\n' "${1:?}" "${2:?}" >&2
  exec false
}

# <varname:string>
function yaml::get_type {
  local address="${1:-:3}"
  [[ "${address}" == '__yn'* ]] || return 2
  declare -p "${address}" &> /dev/null || return 3
  return "${__yaml_typereg["${address}"]:-2}"
}

# <varname:string> <expected_type:map|list>
function yaml::check_type {
  local address="${1:?reference name required}"
  local expected="${2:?type string required (map, list)}"
  yaml::get_type "${address}"
  local type="${?}"

  local expected_enum
  case "${expected}" in
    map) expected_enum=0 ;;
    list) expected_enum=1 ;;
    *) return 1 ;;
  esac

  ((type == expected_enum))
}

# !! <varname_ref:string> <dot_path:string> <parent_node_ref:string>
function yaml::get_leaf {
  local -n target_var_n="${1:?target variable required}"
  local _dot_path="${2:?dot-path required}"
  local _curr_node_name="${3:?parent node name required}"

  local -a _nodes
  IFS='.' read -r -a _nodes <<< "${_dot_path#.}"
  local len=${#_nodes[@]}
  ((len == 0)) && {
    target_var_n="${_curr_node_name}"
    return
  }

  yaml::get_type "${_curr_node_name}"
  local last_type="${?}"
  ((last_type > 1)) && {
    target_var_n=null
    return
  }

  for ((i = 0; i < len - 1; i++)); do
    ((last_type == 1)) && [[ "${_nodes[i]}" != +([0-9]) ]] && yaml::die 'IndexError' 'cannot index array with string '"'${_nodes[i]}'"

    local -n current_map="${_curr_node_name}"
    _curr_node_name="${current_map["${_nodes[i]}"]}"

    yaml::get_type "${_curr_node_name:-:3}"
    last_type="${?}"

    ((last_type > 1)) && yaml::die 'YamlError' "path segment '${_nodes[i]}' in '${_dot_path}' is a value"
  done
  ((last_type == 1)) && [[ "${_nodes[-1]}" != +([0-9]) ]] && yaml::die 'IndexError' 'cannot index array with string '"'${_nodes[-1]}'"

  local -n current_map="${_curr_node_name}"
  target_var_n="${current_map["${_nodes[-1]}"]}"
}

# !! <expected_type:map|list> <dot_path:string> <parent_node_ref:string>
function yaml::ensure {
  local _yaml_type="${1:?type required}"
  local _dot_path="${2:?dot-path required}"
  local _parent_node="${3:?parent node name required}"

  local target_val
  yaml::get_leaf target_val "${_dot_path}" "${_parent_node}"

  [[ -z "${target_val}" ]] && yaml::die 'YamlError' "leaf '${_dot_path}' does not exist"
  yaml::check_type "${target_val}" "${_yaml_type}" \
    || yaml::die 'YamlError' "expected '${_dot_path}' to be a ${_yaml_type}, but it is invalid or missing"
}

# <string_varname:string>
function yaml::escape {
  local -n __value_n="${1:?pass value name}"
  case "${__value_n}" in
    '')
      __value_n='""'
      return 0
      ;;
    true | false) return 2 ;;
    null) return 3 ;;
  esac
  [[ "${__value_n}" == ?([-+])*([0-9._]) ]] && return 1
  __value_n="${__value_n@Q}"            # escape string
  __value_n="${__value_n#\$}"           # remove leading $ (if found)
  __value_n="${__value_n:1:-1}"         # remove '...' quotes added
  __value_n="${__value_n//\'\\\'\'/\'}" # remove '\''
  __value_n="${__value_n//\\\'/\'}"     # remove \' no need to escape
  __value_n="${__value_n//\"/\\\"}"     # escape "
  __value_n="\"${__value_n}\""
  return 0
}

# <node_name:string> [indentation_spaces:int] [colored:bool]
function yaml::dump (
  local _root_map="${1:?Node name required}"
  local indent_size="${2:-2}"
  local colored_print="${3:-false}"

  local c_key="" c_str="" c_num="" c_bool="" c_null="" c_reset=""

  if [[ "${colored_print}" == "true" ]]; then
    c_key="\e[34m"  # Blue
    c_str="\e[32m"  # Green
    c_num="\e[31m"  # Red
    c_bool="\e[33m" # Yellow
    c_null="\e[35m" # Magenta
    c_reset="\e[0m"
  fi

  function __yaml_dump_recurse {
    local curr_node="${1:?Node name required}"
    local indent="${2:-0}"
    local parent_type="${3:-0}"
    local eff_indent=$((parent_type == 1 ? 0 : indent))

    yaml::get_type "${curr_node:-:3}"
    local curr_node_type="${?}"
    local v_color=""

    if ((curr_node_type == 0)); then
      local -n curr_map="${curr_node}"

      for key in "${!curr_map[@]}"; do
        local val="${curr_map["${key}"]}"

        yaml::get_type "${val:-:3}"
        if ((${?} < 2)); then
          printf '%*s%b%s%b:\n' "${eff_indent}" '' "${c_key}" "${key}" "${c_reset}"
          __yaml_dump_recurse "${val}" $((indent + indent_size)) 0
        else
          yaml::escape val
          case "${?}" in
            0) v_color="${c_str}" ;;
            1) v_color="${c_num}" ;;
            2) v_color="${c_bool}" ;;
            3) v_color="${c_null}" ;;
          esac
          printf '%*s%b%s%b: %b%s%b\n' "${eff_indent}" '' "${c_key}" "${key}" "${c_reset}" "${v_color}" "${val}" "${c_reset}"
        fi
        eff_indent="${indent}"
      done

    elif ((curr_node_type == 1)); then
      local -n curr_list="${curr_node}"

      for idx in "${!curr_list[@]}"; do
        local val="${curr_list[idx]}"

        yaml::get_type "${val:-:3}"
        if ((${?} < 2)); then
          printf '%*s- ' "${eff_indent}" ''
          __yaml_dump_recurse "${val}" $((indent + indent_size)) 1
        else
          yaml::escape val
          case "${?}" in
            0) v_color="${c_str}" ;;
            1) v_color="${c_num}" ;;
            2) v_color="${c_bool}" ;;
            3) v_color="${c_null}" ;;
          esac
          printf '%*s- %b%s%b\n' "${eff_indent}" '' "${v_color}" "${val}" "${c_reset}"
        fi
        eff_indent="${indent}"
      done
    else
      yaml::escape curr_node
      case "${?}" in
        0) v_color="${c_str}" ;;
        1) v_color="${c_num}" ;;
        2) v_color="${c_bool}" ;;
        3) v_color="${c_null}" ;;
      esac
      printf '%*s%b%s%b\n' "${indent}" '' "${v_color}" "${curr_node}" "${c_reset}"
    fi
  }

  __yaml_dump_recurse "${_root_map}"
  return 0
)

# !! <varname:string> <file_path:string>
function yaml::load {
  local _root_name="${1:?root node name required}"
  [[ "${_root_name}" != '__yn'* ]] && yaml::die 'NameError' 'Name ref for root has to start with "__yn", got "'"${_root_name}"'"'
  local -
  shopt -s extglob
  local file="${2:?path to file required}"

  [[ -f "${file}" || "${file}" == '/dev/stdin' ]] || yaml::die 'NotFileFound' "${file} is not a file"
  mapfile -t lines < "${file}"

  local tot_lines=${#lines[@]}
  local ln=0
  for (( ; ln < tot_lines; ln++)); do
    [[ "${lines[ln]##*(\ )}" != '#'* ]] && break
  done

  if [[ "${lines[ln]##*(\ )}" == -*(\ *) ]]; then
    declare -ag "${_root_name}=()"
    __yaml_typereg["${_root_name}"]=1
  else
    declare -Ag "${_root_name}=()"
    __yaml_typereg["${_root_name}"]=0
  fi

  local -a node_stack=("${_root_name}")
  local -i indent_size=0
  local -i curr_indent=0
  local -i expected=0
  local -i mln_indent=0
  local -i in_mln=0
  local -i mln_el=-1
  local -i mln_fold=0
  local -i mln_kln=0
  local -i level=0
  local -i last_level=0
  local waits_value=''
  local mln_str=()
  local mln_key=''

  function __join_to_val_by {
    local IFS="${1}"
    val="${*:2}"
  }

  function __yaml_die {
    local pos="${1}"
    local err="${2}"
    local msg="${3}"

    if [[ ! -t 2 ]]; then
      printf '%s: %s\n' "${err}" "${msg}" >&2
      exec false
    fi

    local prev_line=""
    ((ln > 0)) && prev_line="${lines[ln - 1]}"
    local line="${lines[ln++]}"
    printf -v dots '%*s' "${curr_indent}" ""
    dots="${dots// /·}"

    printf '\x1b[1;31mFile "%s", line %d\x1b[0m\n' "${file}" "${ln}" >&2
    local n_len="${#ln}"
    ((ln > 1)) && {
      : "${prev_line%%[! ]*}"
      local plci="${#_}"
      printf -v pldots '%*s' "${plci}" ""
      pldots="${pldots// /·}"
      printf ' \x1b[2m%*s │\x1b[0m \x1b[2m%s\x1b[1;31m%s\x1b[0m\n' "${n_len}" "$((ln - 1))" "${pldots}" "${prev_line:plci}" >&2
    }
    printf ' \x1b[2m%*s │\x1b[0m \x1b[2m%s\x1b[1;31m%s\x1b[0m\n' "${n_len}" "${ln}" "${dots}" "${line:curr_indent}" >&2
    printf ' %*s \x1b[2m│\x1b[0m \x1b[1;31m%*s\x1b[0m\n' "${n_len}" "" "${pos}" '^' >&2
    printf '\x1b[1;31m%s:\x1b[0m %s\n' "${err}" "${msg}" >&2
    exec false
  }

  declare -i __yaml_node_idx=0
  function __yaml_push_node {
    ((level++))
    local -n __node_ref="${node_stack[-1]}"
    local __new_node="${_root_name}_$((++__yaml_node_idx))"

    case "${1:-0}" in
      1) declare -ag "${__new_node}=()" ;;
      *) declare -Ag "${__new_node}=()" ;;
    esac

    if yaml::get_type "${node_stack[-1]:?:3}"; then
      __node_ref["${waits_value:?}"]="${__new_node}"
    else
      __node_ref+=("${__new_node}")
    fi

    __yaml_typereg["${__new_node}"]="${1:-0}"
    node_stack+=("${__new_node}")
  }

  function __yaml_push_value {
    local -n __node_ref="${node_stack[-1]}"
    local __val="${1}"
    case "${__val}" in
      "'"*"'" | '"'*'"') __val="${__val:1:-1}" ;;
    esac
    __val="${__val@E}"
    [[ "${val}" == '__yn'* ]] && __yaml_die "${curr_indent}" 'ValueError' 'Values starting with "__yn" are forbidden'

    if yaml::get_type "${node_stack[-1]:?:3}"; then
      read -r __key <<< "${2:?missing key}"
      [[ -v "__node_ref["${__key:?a cannot be just spaces}"]" ]] \
        && __yaml_die "${curr_indent}" 'YamlError' 'key is already defined'
      __node_ref["${__key}"]="${__val}"
    else
      __node_ref+=("${__val}")
    fi
  }

  local __list_count=0
  function __yaml_parse_line {
    __list_count=0
    while [[ "${line}" == -*(\ *) ]]; do
      while [[ "${line}" == '- '* ]]; do
        line="${line##*(\ )-*(\ )}"
        ((__list_count++))
      done

      if [[ "${line#-}" == ?(#\ *) ]]; then
        # hell nah, cursed yaml (we vibe)
        ((expected = curr_indent + indent_size))
        : "${lines[++ln]%%[! ]*}"
        __indent="${#_}"
        ((__indent != expected)) \
          && __yaml_die "${expected}" 'IndentationError' "expected ${expected}, got ${__indent}"
        [[ "${line}" == '-' ]] \
          && line="- ${lines[ln]:expected}" \
          || line="${lines[ln]:expected}"
      fi
    done

    key=''
    val=''
    while true; do
      read -r -d ':' key_p <<< "${line}" || break
      line="${line#"${key_p}:"}"
      key+="${key_p}"
      [[ -z "${line}" ]] && return
      [[ "${line}" == ' '* ]] && break
    done
    line="${line#"${line%%[! ]*}"}"

    IFS='#' read -ra __hash_splits <<< "${line}"
    local __hash_splits_len="${#__hash_splits[@]}"
    ((__hash_splits_len == 1)) && {
      read -r val <<< "${line}"
      line=''
      return
    }
    [[ -z "${__hash_splits[0]}" ]] && {
      val=''
      return
    }

    val="${line}" # in case of return
    local __comment_index
    local i=-1
    case "${__hash_splits[0]}" in
      '"" '* | "'' "*)
        local __remainder="${__hash_splits[0]:2}"
        if [[ -n "${__remainder//\ /}" ]]; then
          __yaml_die "${curr_indent}" 'InvalidToken' 'trailing text after closing quote'
        fi
        i=0
        ;;
      '"'*)
        while ((i++ < __hash_splits_len)); do
          [[ "${__hash_splits[i]//\\\\/}" == *[!\\]\"+(\ ) ]] && break
        done
        ((i >= __hash_splits_len)) && {
          [[ "${__hash_splits[-1]}" == *'"' ]] && return
          __yaml_die "${curr_indent}" 'InvalidToken' 'trailing text after closing quote'
        }
        ;;
      "'"*)
        while ((i++ < __hash_splits_len)); do
          [[ "${__hash_splits[i]//\'\'/}" == *[!\']\'+(\ ) ]] && break
        done
        ((i >= __hash_splits_len)) && {
          [[ "${__hash_splits[-1]}" == *"'" ]] && return
          __yaml_die "${curr_indent}" 'InvalidToken' 'trailing text after closing quote'
        }
        ;;
      *)
        while ((i++ < __hash_splits_len)); do
          [[ "${__hash_splits[i]}" == *' ' ]] && break
        done
        ((i >= __hash_splits_len)) && return
        ;;
    esac
    __join_to_val_by '#' "${__hash_splits[@]:0:i+1}"
    read -r val <<< "${val}"
    line="${line#"${val} "}"
  }

  local tot_lines=${#lines[@]}
  for (( ; ln < tot_lines; ln++)); do
    ((level < 0)) && yaml::die 'CorrupedState' 'Cannot continue without root map'
    ((level > 63)) && yaml::die 'ParserError' 'Max nesting depth (64) exceeded'
    local line="${lines[ln]}"

    : "${line%%[! ]*}"
    curr_indent="${#_}"
    ((indent_size == 0 && curr_indent > 0)) && indent_size="${curr_indent}"

    case "${line:curr_indent}" in
      '#'*)
        ((in_mln)) || continue
        ;;
      '')
        ((in_mln)) && ((mln_el++))
        continue
        ;;
    esac

    if ((in_mln)); then
      ((indent_size == 0)) && yaml::die 0 'IndentationError' 'Expected indentation'
      ((mln_indent == 0)) && mln_indent="${indent_size}"
      ((mln_el > 0)) && {
        ((!mln_fold)) && ((mln_el++))
        while ((mln_el-- > 0)); do mln_str+=($'\n'); done
      }

      if ((curr_indent >= mln_indent)); then
        if ((mln_el == 0)); then ((mln_fold)) && mln_str+=(' ') || mln_str+=($'\n'); fi
        mln_str+=("${line:mln_indent}")
        mln_el=0
        continue
      else
        __join_to_val_by '' "${mln_str[@]}"

        ((mln_kln != 2)) && val="${val%%*([[:space:]])}"
        [[ -n "${val}" ]] && ((mln_kln == 1 || (mln_fold && mln_kln == 2))) && val+=$'\n'
        __yaml_push_value "${val}" "${mln_key}"

        val=''
        in_mln=0
        mln_str=()
        mln_el=-1
        mln_key=''
        mln_indent=0
        waits_value=''
      fi
    fi
    line="${line:curr_indent}"
    [[ "${line##*(\ )}" == '#'* ]] && continue

    __yaml_parse_line

    if [[ -n "${waits_value}" ]]; then
      if ((curr_indent <= indent_size * level)); then
        if ((__list_count)); then
          ((expected = indent_size * (level + 1)))
          ((curr_indent < indent_size * level)) && waits_value=''
          __yaml_die "${expected}" 'IndentationError' "${waits_value:+list may not be indented as its parent, }expected ${expected}, got ${curr_indent}"
        fi
        __yaml_push_value "" "${waits_value}"
      else
        __yaml_push_node $((__list_count ? 1 : 0))
      fi
      waits_value=''
    fi

    while ((curr_indent < indent_size * level)); do
      ((level--))
      readonly "${node_stack[-1]}"
      unset 'node_stack[-1]'
    done

    ((expected = indent_size * level))
    ((curr_indent != expected)) && __yaml_die "${expected}" 'IndentationError' "expected ${expected}, got ${curr_indent}"

    last_level="${level}"

    if ((__list_count--)); then
      while ((__list_count-- > 0)); do __yaml_push_node 1; done
      [[ -n "${key}" ]] && __yaml_push_node
    elif [[ -z "${key}" ]]; then
      __yaml_die "${curr_indent}" 'MissingKey' "stray value, missing a key"
    elif [[ -z "${val}" ]]; then
      waits_value="${key}"
      continue
    fi

    if [[ "${val}" == [\|\>]?([+-])*(\ ) ]]; then
      in_mln=1
      mln_fold=0
      mln_kln=1
      [[ "${val:0:1}" == '>' ]] && mln_fold=1
      [[ "${val:1:1}" == '-' ]] && mln_kln=0
      [[ "${val:1:1}" == '+' ]] && mln_kln=2
      ((mln_indent = curr_indent + indent_size))
      mln_key="${key}"
      continue
    fi

    waits_value=''
    if [[ -n "${val}" ]]; then
      __yaml_push_value "${val}" "${key}"
    else
      waits_value="${key}"
    fi
  done

  ((in_mln)) && {
    __join_to_val_by '' "${mln_str[@]}"
    ((mln_kln != 2)) && val="${val%%*([[:space:]])}"
    [[ -n "${val}" ]] && ((mln_kln == 1 || (mln_fold && mln_kln == 2))) && val+=$'\n'
    __yaml_push_value "${val}" "${mln_key}"
  }

  readonly "${node_stack[@]}"
  unset -f __yaml_die __yaml_parse_line __yaml_push_node __yaml_push_value __join_to_val_by
  return 0
}
