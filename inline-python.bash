#!/bin/bash

# TODO: this could work for other POSIX shells that have a history builtin

_ilpython_print_usage() (
echo '$ ilpython print("hello world")' >&2
echo '$ ilpython print("hello", end=" "); print("wor" + "ld")' >&2
echo '$ # how is `ilpython` defined?' >&2
)

case "$-" in
  *i*)
    echo 'Luke, trust me.'
    _ilpython_print_usage
    ;;
  *)
    echo 'Use the source, Luke.' >&2
    printf '$ . %s\n' "$0" >&2
    exit 1
    ;;
esac

# IF YOU'RE LOOKING AT THIS SCRIPT WITHOUT TRYING TO FIGURE OUT HOW IT WAS
# WRITTEN, GO BACK NOW AND TRY. IF YOU'VE ALREADY GIVEN UP, THEN READ ON.

get_python_version() {
  local bname='get_python_version' || :

  if [ $# -ne 1 ]; then
    printf 'usage: %s <variable-name>\n' "${bname}" >&2
    return 2
  fi

  # TODO: make this work for arbitrary python versions
  for pyv in python3 python python2 python2.7 python2.8; do
    if command -v "${pyv}" > /dev/null 2>&1; then
      eval "$1"'='"${pyv}" || {
        printf '%s: error returning value %s to variable %s\n' "${bname}" "${pyv}" "$1" >&2
        return 2
      }
      return 0
    fi
  done

  eval "$1"'=' || {
    printf '%s: error returning empty value to %s\n' "${bname}" "$1" >&2
    return 2
  }
  return 1
}

_ilpython_helper() (
bname='_ilpython_helper'

if [ $# -ne 0 ]; then
  printf '%s: bad usage\n' "${bname}" >&2
  exit 1
fi

get_python_version pyversion || {
  printf '%s: could not find python\n' "${bname}" >&2
  exit 2
}

for dep in expr sed "${pyversion}"; do
  command -v "${dep}" > /dev/null 2>&1 || {
    printf '%s: could not find %s\n' "${bname}" "${dep}" >&2
    exit 1
  }
done

cmd_line="$(history 1)" || {
  printf '%s: history failed\n' "${bname}" >&2
  printf '%s: must be run from interactive bash\n' "${bname}" >&2
  exit 1
}

pre_cmd='[[:space:]]*[[:digit:]]\{1,\}[[:space:]]\{1,\}'

expr -- "${cmd_line}" : "${pre_cmd}" > /dev/null 2>&1 || {
  printf '%s: unrecognized history format. is this not bash?\n' "${bname}" 2>&1
  exit 1
}

# XXX: I could try to parse the command line properly, but this is already a
# hack. There's really no need to try to legitimize this.
pre_cmd="${pre_cmd}"'ilpython[[:space:]]\{1,\}\([^[:space:]].*\)$'
expr -- "${cmd_line}" : "${pre_cmd}" > /dev/null 2>&1 || {
  printf 'usage:\n$ ilpython print("hello world")\n' 2>&1
  exit 1
}

pre_cmd='^'"${pre_cmd}"

input_python="$(
printf '%s\n' "${cmd_line}" | \
  sed -e 's/'"${pre_cmd}"'/\1/'
)"

printf '%s\n' "${input_python}" | "${pyversion}" || {
  printf '%s: failed executing python code\n' "${bname}" >&2
  exit 1
}
)

alias ilpython='_ilpython_helper #'
