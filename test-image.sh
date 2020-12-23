#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
nk="\033[0;31m⨯\033[0m "  # Not OK
ok="\033[0;32m✔️\033[0m "  # OK

echo -e "${li:?}Arranging tests…"

function make_source() {
  mkdir -p "${1:?}"
  echo 'title = "My New Hugo Site"' > "${1:?}/config.toml"
}

make_source .
make_source empty-args-workspace
make_source sub-workspace
make_source alt-workspace
make_source upload-workspace
make_source upload-with-prefix-workspace

ref="${GITHUB_REF:?}"
branch="${ref##*/}"

aws s3 rm "s3://${PREFIX_TEST_BUCKET:?}" --recursive
aws s3 rm "s3://${ROOT_TEST_BUCKET:?}"   --recursive

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
verify empty-args-workspace/public
verify sub-workspace/public
verify alt-workspace/public

aws s3 sync "s3://${ROOT_TEST_BUCKET:?}"                   ./upload-public
verify upload-public

aws s3 sync "s3://${PREFIX_TEST_BUCKET:?}/${GITHUB_SHA:?}" ./upload-with-prefix-public
verify upload-with-prefix-public

echo -e "${ok:?}All tests passed"
