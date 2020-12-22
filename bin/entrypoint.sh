#!/bin/bash -e

hugo --source /src --destination /pub --minify

echo "Proofing..."
htmlproofer /pub            \
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

if [ "${S3_BUCKET:=}" == "" ]; then
  exit 0
fi

s3_path="s3://${S3_BUCKET:?}${S3_PREFIX:=}"

header_args=(-bucket "${S3_BUCKET:?}")

usr_header_config=/src/.s3headersetter.yml
sys_header_config=/config/.s3headersetter.yml

if [ -f "${usr_header_config}" ]; then
  header_args+=(-config "${usr_header_config}")
else
  header_args+=(-config "${sys_header_config}")
fi

if [ "${S3_PREFIX:=}" != "" ]; then
  header_args+=(-key-prefix "${S3_PREFIX:?}")
fi

if [ "${DEPLOY:=0}" == "1" ]; then
  echo "DRY RUN: Would upload to:      ${s3_path}"
  echo "DRY RUN: Would set S3 headers: s3headersetter ${header_args[*]}"
  exit 0
fi

aws s3 sync --delete public "s3://${s3_path:?}"
s3headersetter "${header_args[@]}"
