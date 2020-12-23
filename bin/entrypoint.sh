#!/bin/bash -e

# Helpful constants:

li="\033[1;34m•\033[0m "  # List item
ok="\033[0;32m✔️\033[0m "  # OK

# Default values:

src=/src
pub=/pub

# Read command line arguments:

while [[ $1 = -* ]]; do
  arg=$1; shift

  case ${arg} in
    --public)
      pub=${1:?}; shift;;

    --s3-bucket)
      s3_bucket=${1:?}; shift;;

    --s3-prefix)
      s3_prefix=${1:?}; shift;;

    --source)
      src=${1:?}; shift;;

    *)
      echo "Unexpected argument: ${arg}"
      exit 1
      ;;
  esac
done

# Log the values we'll run with:

echo -e "${li:?}Source path: ${src:?}"
echo -e "${li:?}Public path: ${pub:?}"

# Build:

hugo --source "${src:?}" --destination "${pub:?}" --minify

# Lint:

echo -e "${li:?}Linting…"
htmlproofer "${pub:?}"      \
  --allow-hash-href         \
  --check-favicon           \
  --check-html              \
  --check-img-http          \
  --check-opengraph         \
  --disable-external        \
  --report-invalid-tags     \
  --report-missing-names    \
  --report-script-embeds    \
  --report-missing-doctype  \
  --report-eof-tags         \
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

usr_header_config="${src:?}/.s3headersetter.yml"
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

# If this is a dry-run then stop now:

if [ "${DEPLOY:=0}" == "1" ]; then
  echo "This is a dry-run, so gracefully stopping now."
  exit 0
fi

# Upload:

echo -e "${li:?}Uploading…"
aws s3 sync --delete "${pub:?}" "${s3_path:?}"

# Set HTTP headers:

echo -e "${li:?}Setting HTTP headers…"
s3headersetter "${header_args[@]}"

# Done!

echo -e "${ok:?}OK"
