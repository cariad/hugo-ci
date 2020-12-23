#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
ok="\033[0;32m✔️\033[0m "  # OK

src=/src
pub=/pub

while [[ $1 = -* ]]; do
  arg=$1; shift

  case ${arg} in
    --public)
      pub=${1:?}; shift;;

    --s3_bucket)
      s3_bucket=${1:?}; shift;;

    --source)
      src=${1:?}; shift;;

    *)
      echo "Unexpected argument: ${arg}"
      exit 1
      ;;
  esac
done

echo -e "${li:?}Source path: ${src:?}"
echo -e "${li:?}Public path: ${pub:?}"

hugo --source "${src:?}" --destination "${pub:?}" --minify

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

if [ -z "${s3_bucket}" ]; then
  exit 0
fi

echo -e "${li:?}S3 bucket: ${s3_bucket:?}"
s3_path="s3://${s3_bucket:?}"

if [ "${S3_PREFIX:=}" != "" ]; then
  echo -e "${li:?}S3 prefix: ${S3_PREFIX:=}"
  s3_path="s3://${s3_bucket:?}/${S3_PREFIX:?}"
fi

echo -e "${li:?}S3 path: ${s3_path:?}"

header_args=(-bucket "${s3_bucket:?}")

usr_header_config="${src:?}/.s3headersetter.yml"
sys_header_config=/config/.s3headersetter.yml

if [ -f "${usr_header_config}" ]; then
  header_args+=(-config "${usr_header_config}")
else
  header_args+=(-config "${sys_header_config}")
fi

if [ "${S3_PREFIX:=}" != "" ]; then
  header_args+=(-key-prefix "${S3_PREFIX:?}")
fi

echo -e "${li:?}s3headersetter arguments: ${header_args[*]}"

if [ "${DEPLOY:=0}" == "1" ]; then
  echo "This is a dry-run, so gracefully stopping now."
  exit 0
fi

echo -e "${li:?}Uploading…"
aws s3 sync --delete "${pub:?}" "${s3_path:?}"

echo -e "${li:?}Setting HTTP headers…"
s3headersetter "${header_args[@]}"

echo -e "${ok:?}OK"
