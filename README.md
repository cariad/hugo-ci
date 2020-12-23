# cariad/hugo-ci

`cariad/hugo-ci` is a Docker image for building, validating and deploying [Hugo](https://github.com/gohugoio/hugo) sites:

1. **Build** your Hugo site from source.
1. **Validate** your site with [github.com/gjtorikian/html-proofer](https://github.com/gjtorikian/html-proofer).
1. (Optional) **Deploy** to your S3 bucket.
1. Fix your files’ **HTTP headers** with [github.com/cariad/s3headersetter](https://github.com/cariad/s3headersetter).

**Building Hugo sites in GitHub? Check out my _Hugo CI_ GitHub Action: [github.com/cariad/hugo-ci-action](https://github.com/cariad/hugo-ci-action)**

**Deploying static sites to Amazon Web Services? Check out my infrastructure: [sitestack.cloud](https://sitestack.cloud)**

## Configuration

### Arguments

| Argument      | Description                               | Default     |
|---------------|-------------------------------------------|-------------|
| `--public`    | Path _within the container_ to build to   | `/pub`      |
| `--s3-bucket` | S3 bucket to upload to                    | _No upload_ |
| `--s3-prefix` | S3 prefix to upload to                    | _No prefix_ |
| `--s3-region` | S3 bucket region                          | `us-east-1` |
| `--source`    | Path _within the container_ to build from | `/src`      |

### Environment variables

`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and (if required) `AWS_SESSION_TOKEN` environment variables are required only when deploying to an S3 bucket.

### HTTP headers

If you opt to deploy your site to an S3 bucket, you can set some custom HTTP headers for your uploaded files:

- `Cache-Control` prescribes how long a file should be cached. Images, for example, typically don’t change as often as HTML files, and so can be granted much longer cache durations to aid performance.
- `Content-Type` prescribes the type of a file. S3 has a jolly good try at identifying _some_ file types, but it’s far from complete. At time of writing, for example, S3 did not identity `.woff` files as `font/woff2`.

To set custom HTTP headers:

1. Refer to [github.com/cariad/s3headersetter](https://github.com/cariad/s3headersetter) to create an `s3headersetter` configuration file.
1. Save your configuration file as `.s3headersetter.yml` in the root of your source project.

If you don’t create `.s3headersetter.yml` then the following defaults will take effect:

| File pattern | `Cache-Control`          | `Content-Type` |
|--------------|--------------------------|----------------|
| `.html`      | `max-age=3600, public`   | _Defer to S3_  |
| `.css`       | `max-age=604800, public` | _Defer to S3_  |
| `.woff2`     | _Defer to S3_            | `font/woff2`   |

## Examples

### Build and test your local development project

```bash
docker run                                             \
  --mount "type=bind,source=$(pwd),target=/src"        \
  --mount "type=bind,source=$(pwd)/public,target=/pub" \
  --rm                                                 \
  cariad/hugo-ci
```

### Build, test and upload your local development project

```bash
docker run                                                     \
  --env       AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?}         \
  --env       AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?} \
  --mount     "type=bind,source=$(pwd),target=/workspace"      \
  --rm                                                         \
  cariad/hugo-ci                                               \
  --source    /workspace                                       \
  --public    /workspace/public                                \
  --s3-bucket mybucket
```

### Build, test and upload your GitHub project

Check out my _Hugo CI_ GitHub Action: [github.com/cariad/hugo-ci-action](https://github.com/cariad/hugo-ci-action).

## Acknowledgements

- ❤️ [github.com/gohugoio/hugo](https://github.com/gohugoio/hugo)
- ❤️ [github.com/gjtorikian/html-proofer)](https://github.com/gjtorikian/html-proofer)
- 👩🏼‍💻 [github.com/cariad/s3headersetter](https://github.com/cariad/s3headersetter)
