# kitsh

*A collection of shell scripts that work.*

## What's This?

Personal bash utilities and libraries for making shell scripting less painful. Built with performance in mind (process substitution over subshells, that kind of thing).

## Installation

```bash
git clone https://github.com/klapptnot/kitsh && cd kitsh
bash main.sh

# uninstall with
bash main.sh uninstall
```

Installs to `~/.local/bin`. Add the bin directory to your PATH if it's not there already.

The installer handles environment-specific filtering automatically—Termux-only scripts won't be linked on desktop systems, and scripts requiring GLIBC regex support (via [barg.sh](https://github.com/klapptnot/barg.sh)) won't be linked on Termux/Bionic. This is managed by [bstow](https://github.com/klapptnot/bstow), which gets downloaded during installation.

## Structure

- **bin/** — Executable scripts (various utilities)
- **lib/** — Reusable bash libraries
- **.bash_env** — Environment setup for the making source fail if not sourcing anything

*Built with spite for subshells and love for bash*
