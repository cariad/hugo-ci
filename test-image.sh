#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
nk="\033[0;31m⨯\033[0m "  # Not OK
ok="\033[0;32m✔️\033[0m "  # OK

echo -e "${li:?}Arranging tests…"
echo 'title = "My New Hugo Site"' > config.toml
mkdir subdirectory
echo 'title = "My New Hugo Site"' > subdirectory/config.toml

ref="${GITHUB_REF:?}"
branch="${ref##*/}"
echo -e "${li:?}Branch: ${branch:?}"

echo -e "${li:?}Starting containers…"
BRANCH="${branch:?}" docker-compose up

echo -e "${li:?}Verifying results…"

function assert() {
  expect=7
  local expect
  actual=$(find "${1:?}" | wc -l)
  local actual

  if [ ! "${actual:?}" -eq "${expect:?}" ]; then
    echo -e "${nk:?}Expected ${expect:?} files in ${1:?} but found ${actual:?}."
    exit 1
  fi

  echo -e "${ok:?}${1:?} OK"
}

assert public
assert subdirectory/public

aws s3 sync s3://hugoci-test-bucket-248eadwvcive ./uploaded-root
assert uploaded-root

aws s3 sync "s3://hugoci-test-bucket-248eadwvcive/${GITHUB_SHA:?}" ./uploaded-subdirectory
assert uploaded-subdirectory

mkdir empty
aws s3 sync --delete empty s3://hugoci-test-bucket-248eadwvcive

echo -e "${ok:?}OK!"
