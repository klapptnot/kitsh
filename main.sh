#!/usr/bin/bash
# works on *correct* machines

set -euo pipefail

read -r SCRIPT_PATH < <(realpath "${BASH_SOURCE[0]}")
readonly SCRIPT_DIR="${SCRIPT_PATH%/*}"
readonly LOCAL_BIN="${HOME}/.local/bin"
readonly LOCAL_LIB="${HOME}/.local/lib/kitsh"

function uninstall {
  cd "${SCRIPT_DIR}"

  if [[ -L ~/.bash_env ]]; then
    echo "Unlinking ~/.bash_env..."
    unlink ~/.bash_env
  fi

  echo "Uninstalling bash tools using bstow..."

  if [[ -x "${SCRIPT_DIR}/bin/bstow" ]]; then
    echo "Unlinking bin/ from ${LOCAL_BIN}..."
    "${SCRIPT_DIR}/bin/bstow" -Dvf "${SCRIPT_DIR}/ignore.sh" -t "${LOCAL_BIN}" -d "${SCRIPT_DIR}/bin"

    echo "Unlinking lib/ from ${LOCAL_LIB}..."
    "${SCRIPT_DIR}/bin/bstow" -Dvf "${SCRIPT_DIR}/ignore.sh" -t "${LOCAL_LIB}" -d "${SCRIPT_DIR}/lib"
  else
    echo "Warning: bstow not found, skipping symlink removal" >&2
  fi

  [ -v TERMUX_APP__PACKAGE_NAME ] || {
    if [[ -f "${SCRIPT_DIR}/lib/barg.sh" ]]; then
      echo "Removing barg.sh from ${SCRIPT_DIR}/lib/..."
      rm -f "${SCRIPT_DIR}/lib/barg.sh"
    fi
  }

  if [[ -f "${SCRIPT_DIR}/bin/bstow" ]]; then
    echo "Removing bstow from ${SCRIPT_DIR}/bin/..."
    rm -f "${SCRIPT_DIR}/bin/bstow"
  fi

  echo "Uninstallation complete!"
}

function install {
  cd "${SCRIPT_DIR}"

  echo "Installing bash tools using bstow..."

  mkdir -p "${LOCAL_BIN}" "${LOCAL_LIB}"

  [ -v TERMUX_APP__PACKAGE_NAME ] || {
    echo "Downloading barg.sh to ${SCRIPT_DIR}/lib/..."
    curl -fsSL https://raw.githubusercontent.com/klapptnot/barg.sh/main/barg.sh -o "${SCRIPT_DIR}/lib/barg.sh" || {
      echo "Error: curl failed to download barg.sh to ${SCRIPT_DIR}/lib/" >&2
      exit 1
    }
  }

  echo "Downloading bstow to ${SCRIPT_DIR}/bin/..."
  curl -fsSL https://raw.githubusercontent.com/klapptnot/bstow/main/bstow -o "${SCRIPT_DIR}/bin/bstow" || {
    echo "Error: curl failed to download bstow to ${SCRIPT_DIR}/bin/" >&2
    exit 1
  }

  chmod 755 "${SCRIPT_DIR}/bin/bstow"

  if [[ ! -x "${SCRIPT_DIR}/bin/bstow" ]]; then
    echo "Error: bstow not found in ${SCRIPT_DIR}/bin/" >&2
    exit 1
  fi

  echo "Linking bin/ to ${LOCAL_BIN}..."
  "${SCRIPT_DIR}/bin/bstow" -Svf "${SCRIPT_DIR}/ignore.sh" -t "${LOCAL_BIN}" -d "${SCRIPT_DIR}/bin"

  echo "Linking lib/ to ${LOCAL_LIB}..."
  "${SCRIPT_DIR}/bin/bstow" -Svf "${SCRIPT_DIR}/ignore.sh" -t "${LOCAL_LIB}" -d "${SCRIPT_DIR}/lib"

  [[ -e ~/.bash_env ]] || {
    echo "Linking .bash_env to ${HOME}..."
    ln -sf "${SCRIPT_DIR}/.bash_env" ~/.bash_env
  }

  echo "Installation complete!"
  [[ ":${PATH}:" != *":${LOCAL_BIN}:"* ]] && echo "Add ${LOCAL_BIN} to your PATH"
}

function main {
  local action="${1:-install}"

  case "${action}" in
    install | add | i | a)
      install
      ;;
    uninstall | remove | u | r)
      uninstall
      ;;
    *)
      printf 'Error: Unknown action "%s"\n' "${action}" >&2
      printf 'Usage: %s [install|uninstall]\n' "${0}" >&2
      exit 1
      ;;
  esac
}

main "${@}"
