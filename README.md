# cariad/hugo-ci

A Docker image for building, testing and deploying Hugo sites.

## What’s onboard?

`cariad/hugo-ci` will:

1. Build your Hugo site from source.
1. Validate your built site via [gjtorikian/html-proofer](https://github.com/gjtorikian/html-proofer).

If you opt to deploy your site, `cariad/hugo-ci` will:

1. Upload to your S3 bucket.
1. Set your files’ HTTP headers via [cariad/s3headersetter](https://github.com/cariad/s3headersetter).

For an (almost) one-click deployment of an S3 bucket and everything else you need to host a static site in Amazon Web Services, check out [sitestack.cloud](https://sitestack.cloud).

## Setting HTTP headers for uploaded files

If you opt to deploy your site to an S3 bucket, then you can set some custom HTTP headers on your files:

- `Cache-Control` prescribes how long a file should be cached. Images, for example, typically don’t change as often as HTML files, and so can be granted much longer cache durations to aid performance.
- `Content-Type` prescribes the content of a file. S3 has a jolly good try at identifying _some_ file types, but it’s far from complete. At time of writing, for example, S3 did not identity `.woff` files as `font/woff2`.

To set custom headers, refer to [cariad/s3headersetter](https://github.com/cariad/s3headersetter) for guidance to create an `s3headersetter` configuration file, then save it as `.s3headersetter.yml` in the root of your source project.

If you don’t create `.s3headersetter.yml` then the following defaults will take effect:

| File pattern | `Cache-Control`          | `Content-Type` |
|--------------|--------------------------|----------------|
| `.html`      | `max-age=3600, public`   | _Defer to S3_  |
| `.css`       | `max-age=604800, public` | _Defer to S3_  |
| `.woff2`     | _Defer to S3_            | `font/woff2`   |

## Running locally

The key notes for running `cariad/hugo-ci` are:

- Your source directory must be mapped to `/src`.
- Your build directory must exist and be mapped to `/pub`.
- To perform a deployment:
    - The `S3_BUCKET` environment variable must be set to thw name of your bucket.
    - To deploy to a key prefix, set `S3_PREFIX`. Do not include a trailing slash.

This sample script will take the current working directory as the source, and the `public` subdirectory as the build destination:

```bash
#!/bin/bash

src_dir="$(pwd)"
pub_dir="$(pwd)/public"

rm -rf "${pub_dir:?}"
mkdir  "${pub_dir:?}"

docker run                                            \
  --mount "type=bind,source=${src_dir:?},target=/src" \
  --mount "type=bind,source=${pub_dir:?},target=/pub" \
  --rm                                                \
  cariad/hugo-ci
```

To include a deployment, set the `S3_BUCKET` and (if required) `S3_PREFIX` environment variables:

```bash
docker run                                            \
  --env   S3_BUCKET=mywebsitesbucket                  \
  --env   S3_PREFIX=mymicrositeprefix                 \
  --mount "type=bind,source=${src_dir:?},target=/src" \
  --mount "type=bind,source=${pub_dir:?},target=/pub" \
  --rm                                                \
  cariad/hugo-ci
```

## Running in GitHub actions

See [github.com/cariad/hugo-ci-action](https://github.com/cariad/hugo-ci-action).
