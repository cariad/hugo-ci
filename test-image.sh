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
make_source alt-workspace


ref="${GITHUB_REF:?}"
branch="${ref##*/}"

aws s3 rm "s3://${S3_BUCKET:?}" --recursive

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

verify public                # "root" scenario
verify alt-workspace/public  # "alt-workspace" scenario

# verify custom-public
# verify subdirectory/public

# aws s3 sync "s3://${S3_BUCKET:?}/${GITHUB_SHA:?}" ./public-with-prefix
# verify public-with-prefix
# aws s3 rm "s3://${S3_BUCKET:?}/${GITHUB_SHA:?}" --recursive

# aws s3 sync "s3://${S3_BUCKET:?}" ./uploaded-root
# verify uploaded-root

# Don't erase this "root" deployment; go check the HTTP headers.

echo -e "${ok:?}OK!"
