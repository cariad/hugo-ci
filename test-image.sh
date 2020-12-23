#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
nk="\033[0;31m⨯\033[0m "  # Not OK
ok="\033[0;32m✔️\033[0m "  # OK

bucket=hugoci-test-bucket-248eadwvcive

echo -e "${li:?}Arranging tests…"
echo 'title = "My New Hugo Site"' > config.toml
mkdir subdirectory
echo 'title = "My New Hugo Site"' > subdirectory/config.toml

ref="${GITHUB_REF:?}"
branch="${ref##*/}"

aws s3 rm "s3://${bucket:?}" --recursive

echo -e "${li:?}Starting containers…"
BRANCH="${branch:?}" docker-compose up

echo -e "${li:?}Verifying results…"

function verify() {
  local actual
  local expect

  actual=$(find "${1:?}" | wc -l)
  expect=7

  if [ ! "${actual:?}" -eq "${expect:?}" ]; then
    echo -e "${nk:?}Expected ${expect:?} files in ${1:?} but found ${actual:?}."
    exit 1
  fi

  echo -e "${ok:?}${1:?} OK"
}

verify public
verify custom-public
verify subdirectory/public

bucket=hugoci-test-bucket-248eadwvcive

aws s3 sync "s3://${bucket:?}/${GITHUB_SHA:?}" ./uploaded-with-prefix
verify uploaded-with-prefix
aws s3 rm "s3://${bucket:?}/${GITHUB_SHA:?}" --recursive

aws s3 sync "s3://${bucket:?}" ./uploaded-root
verify uploaded-root

# I intentionally don't erase this "root" deployment so I can check the HTTP
# headers.

echo -e "${ok:?}OK!"
