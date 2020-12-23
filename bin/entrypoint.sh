#!/bin/bash -e

# Helpful constants:

li="\033[1;34m•\033[0m "  # List item
ok="\033[0;32m✔️\033[0m "  # OK

# Read command line arguments:

while [[ $1 = -* ]]; do
  arg=$1; shift

  case ${arg} in
    --workspace)
      [ -n "${1}" ] && workspace=${1%%/}
      shift;;

    --s3-bucket)
      [ -n "${1}" ] && s3_bucket=${1:?}
      shift;;

    --s3-prefix)
      [ -n "${1}" ] && s3_prefix=${1:?}
      shift;;

    --s3-region)
      [ -n "${1}" ] && AWS_DEFAULT_REGION=${1:?} && export AWS_DEFAULT_REGION
      shift;;

    *)
      echo "Unexpected argument: ${arg}"
      exit 1
      ;;
  esac
done

# Resolve defaults:

if [ -z "${workspace}" ]; then
  workspace=/workspace
  echo -e "${li:?}Workspace: ${workspace:?} (default)"
else
  echo -e "${li:?}Workspace: ${workspace:?}"
fi

public="${workspace:?}/public"
echo -e "${li:?}Public:    ${public:?}"
echo -e "${li:?}Region:    ${AWS_DEFAULT_REGION:?}"

# Build:

hugo --source "${workspace:?}" --destination "${public:?}" --minify

# Lint:

echo -e "${li:?}Linting…"
htmlproofer "${public:?}"  \
  --allow-hash-href        \
  --check-favicon          \
  --check-html             \
  --check-img-http         \
  --check-opengraph        \
  --disable-external       \
  --report-invalid-tags    \
  --report-missing-names   \
  --report-script-embeds   \
  --report-missing-doctype \
  --report-eof-tags        \
  --report-mismatched-tags

echo -e "${ok:?} OK"

# If we have no hosting details then stop now:

if [ -z "${s3_bucket}" ]; then
  exit 0
fi

# Build S3 path:

echo -e "${li:?}S3 bucket: ${s3_bucket:?}"

s3_path="s3://${s3_bucket:?}"

if [ -n "${s3_prefix}" ]; then
  echo -e "${li:?}S3 prefix: ${s3_prefix:?}"
  s3_path="s3://${s3_bucket:?}/${s3_prefix:?}"
fi

echo -e "${li:?}S3 path: ${s3_path:?}"

# Build s3headersetter arguments:

header_args=(-bucket "${s3_bucket:?}")

usr_header_config="${workspace:?}/.s3headersetter.yml"
sys_header_config=/config/.s3headersetter.yml

if [ -f "${usr_header_config}" ]; then
  header_args+=(-config "${usr_header_config}")
else
  header_args+=(-config "${sys_header_config}")
fi

if [ -n "${s3_prefix}" ]; then
  header_args+=(-key-prefix "${s3_prefix:?}")
fi

echo -e "${li:?}s3headersetter arguments: ${header_args[*]}"

# Upload:

echo -e "${li:?}Uploading…"
aws s3 sync --delete "${public:?}" "${s3_path:?}"

# Set HTTP headers:

echo -e "${li:?}Setting HTTP headers…"
s3headersetter "${header_args[@]}"

# Done!

echo -e "${ok:?}OK"
