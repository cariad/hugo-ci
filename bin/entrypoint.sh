#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
ok="\033[0;32m✔️\033[0m "  # OK

src=${SOURCE:=/src}
echo -e "${li:?}Source path: ${src:?}"

pub=${PUBLIC:=/pub}
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

if [ "${S3_BUCKET:=}" == "" ]; then
  exit 0
fi

echo -e "${li:?}S3 bucket: ${S3_BUCKET:?}"
s3_path="s3://${S3_BUCKET:?}"

if [ "${S3_PREFIX:=}" != "" ]; then
  echo -e "${li:?}S3 prefix: ${S3_PREFIX:=}"
  s3_path="s3://${S3_BUCKET:?}/${S3_PREFIX:?}"
fi

echo -e "${li:?}S3 path: ${s3_path:?}"

header_args=(-bucket "${S3_BUCKET:?}")

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
