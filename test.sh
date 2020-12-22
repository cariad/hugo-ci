#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
nk="\033[0;31m⨯\033[0m "  # Not OK
ok="\033[0;32m✔️\033[0m "  # OK



# VALIDATE SHELL SCRIPTS

count=0

while IFS="" read -r file_path
do
  echo -e "${li:?}${file_path:?}"
  shellcheck --check-sourced --enable=all --severity style -x "${file_path:?}"
  count=$((count + 1))
done < <(find . -name "*.sh")

plural() {
  if [[ "${1:?}" == "1" ]]; then
    echo "script"
  else
    echo "scripts"
  fi
}

if [[ "${expect:=${count:?}}" != "${count:?}" ]]; then
  echo -e "${nk:?}Expected ${expect:?} $(plural "${expect:?}") but found ${count:?}."
  exit 1
fi

if [[ ${count:?} == 0 ]]; then
  echo -e "${nk:?}No shell scripts found."
  exit 2
fi

echo -e "${ok:?}${count:?} $(plural "${count:?}") validated."



# VALIDATE YAML

pipenv sync --dev
pipenv run yamllint . --strict



# VALIDATE IMAGE

function clean() {
  echo -e "${li:?}Cleaning…"
  rm -f  config.toml
  rm -rf public
  rm -rf resources
  rm -rf subdirectory
}

clean

echo -e "${li:?}Pulling \"cariad/hugo-ci:latest\"…"
docker pull cariad/hugo-ci:latest

echo -e "${li:?}Building \"cariad/hugo-ci:local\"…"
docker build                         \
  --cache-from cariad/hugo-ci:latest \
  --tag        cariad/hugo-ci:local  \
  .

echo -e "${li:?}Arranging tests…"
mkdir public
echo 'title = "My New Hugo Site"' > config.toml
mkdir subdirectory
echo 'title = "My New Hugo Site"' > subdirectory/config.toml

echo -e "${li:?}Starting containers…"
docker-compose up

echo -e "${li:?}Verifying results…"

expect=7

actual=$(find public | wc -l)
if [ ! "${actual:?}" -eq "${expect:?}" ]; then
  echo -e "${nk:?}Expected ${expect:?} files in ./public but found ${actual:?}."
fi

actual=$(find subdirectory/public | wc -l)
if [ ! "${actual:?}" -eq "${expect:?}" ]; then
  echo -e "${nk:?}Expected ${expect:?} files in ./subdirectory/public but found ${actual:?}."
fi

clean

echo -e "${ok:?}OK!"
