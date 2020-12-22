# cariad/hugo-ci

`cariad/hugo-ci` is a Docker image for building, testing and deploying [Hugo](https://github.com/gohugoio/hugo) sites:

`cariad/hugo-ci` will:

1. **Build** your Hugo site from source.
1. **Validate** your site with [github.com/gjtorikian/html-proofer](https://github.com/gjtorikian/html-proofer).
1. (Optional) **Upload** to your S3 bucket.
1. (Optional) Fix your files’ **HTTP headers** with [github.com/cariad/s3headersetter](https://github.com/cariad/s3headersetter).

**Building Hugo sites in GitHub? Check out my _Hugo CI_ GitHub Action: [github.com/cariad/hugo-ci-action](https://github.com/cariad/hugo-ci-action)**

**Deploying static sites to Amazon Web Services? Check out my infrastructure: [sitestack.cloud](https://sitestack.cloud)**

## Configuration

### Environment variables

| Environment variable    | Default | Description                                    | Required                                                     |
|-------------------------|---------|------------------------------------------------|--------------------------------------------------------------|
| `SOURCE`                | `/src`  | Path to website source files                   | Optional                                                     |
| `PUBLIC`                | `/pub`  | Path to website build directory                | Optional                                                     |
| `S3_BUCKET`             |         | Name of S3 bucket to upload to                 | Only to upload                                               |
| `S3_PREFIX`             |         | S3 prefix to upload to                         | Only to upload to an S3 prefix                               |
| `AWS_ACCESS_KEY_ID`     |         | Access key ID for S3 upload authentication     | Only to upload and not running with an AWS instance profile  |
| `AWS_SECRET_ACCESS_KEY` |         | Secret access key for S3 upload authentication | Only to upload and not running with an AWS instance profile  |
| `AWS_SESSION_TOKEN`     |         | Session token S3 upload authentication         | Only to upload and authenticating with temporary credentials |
| `DEPLOY`                | `1`     | Set to `0` to perform a dry-run                | Optional                                                     |

### HTTP headers

If you opt to deploy your site to an S3 bucket, you can set some custom HTTP headers for your uploaded files:

- `Cache-Control` prescribes how long a file should be cached. Images, for example, typically don’t change as often as HTML files, and so can be granted much longer cache durations to aid performance.
- `Content-Type` prescribes the type of a file. S3 has a jolly good try at identifying _some_ file types, but it’s far from complete. At time of writing, for example, S3 did not identity `.woff` files as `font/woff2`.

To set custom headers, refer to [github.com/cariad/s3headersetter](https://github.com/cariad/s3headersetter) for guidance to create an `s3headersetter` configuration file, then save it as `.s3headersetter.yml` in the root of your source project.

If you don’t create `.s3headersetter.yml` then the following defaults will take effect:

| File pattern | `Cache-Control`          | `Content-Type` |
|--------------|--------------------------|----------------|
| `.html`      | `max-age=3600, public`   | _Defer to S3_  |
| `.css`       | `max-age=604800, public` | _Defer to S3_  |
| `.woff2`     | _Defer to S3_            | `font/woff2`   |

## Running locally

`cariad/hugo-ci` is great for building and testing your Hugo sites locally.

For an easy life, I recommend:

- Map your local source directory to `/src` in the container.
- Map your local build directory to `/pub` in the container. This directory must exist.

This sample script will take the current working directory as the source, and the `public` subdirectory as the build destination:

```bash
#!/bin/bash -e

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

To run this script against your local development directory:

1. Copy-paste the script into `test.sh`.
1. Give the script permission to execute with `chmod +x test.sh`.
1. Run it with `./test.sh`.

You should see a response like this:

```text
Start building sites …

                   | EN
-------------------+------
  Pages            |  22
  Paginator pages  |   0
  Non-page files   |   6
  Static files     |  48
  Processed images | 139
  Aliases          |   1
  Sitemaps         |   1
  Cleaned          |   0

Total in 3343 ms
Proofing...
Running ["ScriptCheck", "OpenGraphCheck", "ImageCheck", "HtmlCheck", "FaviconCheck", "LinkCheck"] on ["/pub"] on *.html...


Ran on 15 files!


HTML-Proofer finished successfully.
```

…and the `public` directory should contain your built website.

## Acknowledgements

- ❤️ [github.com/gohugoio/hugo](https://github.com/gohugoio/hugo)
- ❤️ [github.com/gjtorikian/html-proofer)](https://github.com/gjtorikian/html-proofer)
- 👩🏼‍💻 [github.com/cariad/s3headersetter](https://github.com/cariad/s3headersetter)
