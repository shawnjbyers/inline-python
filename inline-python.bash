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

_ilpython_helper() (
dz='_ilpython_helper' # dz == dollar zero == $0

if [ $# -ne 0 ]
then
  printf '%s: bad usage\n' "${dz}" >&2
  exit 1
fi

for dep in expr sed python3
do
  command -v "${dep}" > /dev/null 2>&1 || {
    printf '%s: could not find %s\n' "${dz}" "${dep}" >&2
    exit 1
  }
done

cmd_line="$(history 1)" || {
  printf '%s: history failed\n' "${dz}" >&2
  printf '%s: must be run from interactive bash\n' "${dz}" >&2
  exit 1
}

pre_cmd='[[:space:]]*[[:digit:]]\+[[:space:]]\+'

expr -- "${cmd_line}" : "${pre_cmd}" > /dev/null 2>&1 || {
  printf '%s: unrecognized history format. is this not bash?\n' "${dz}" 2>&1
  exit 1
}

# XXX: I could try to parse the command line properly, but this is already a
# hack. There's really no need to try to legitimize this.
pre_cmd="${pre_cmd}"'ilpython[[:space:]]\+\([^[:space:]].*\)$'
expr -- "${cmd_line}" : "${pre_cmd}" > /dev/null 2>&1 || {
  printf 'usage:\n$ ilpython print("hello world")\n' 2>&1
  exit 1
}

pre_cmd='^'"${pre_cmd}"

input_python="$(
printf '%s\n' "${cmd_line}" | \
  sed -e 's/'"${pre_cmd}"'/\1/'
)"

printf '%s\n' "${input_python}" | python3 || {
  printf '%s: failed executing python code\n' "${dz}" >&2
  exit 1
}
)

alias ilpython='_ilpython_helper #'
