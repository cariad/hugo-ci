#!/bin/bash -e

li="\033[1;34m↪\033[0m "  # List item
nk="\033[0;31m⨯\033[0m "  # Not OK
ok="\033[0;32m✔️\033[0m "  # OK

################################################################################
# TEST SHELL SCRIPTS

expect=3
found=0

while IFS="" read -r file_path
do
  echo -e "${li:?}${file_path:?}"
  shellcheck --check-sourced --enable=all --severity style -x "${file_path:?}"
  found=$((found + 1))
done < <(find . -name "*.sh")

if [[ "${expect:?}" != "${found:?}" ]]; then
  echo -e "${nk:?}Expected ${expect:?} scripts but found ${found:?}"
  exit 1
fi

echo -e "${ok:?}${found:?} scripts validated"


################################################################################
# TEST YAML

pipenv sync --bare --dev > /dev/null
pipenv run yamllint . --strict
echo -e "${ok:?}YAML OK"
