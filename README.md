# hugo-site-ci

Docker image for continuous build, test and deploy of Hugo sites.

```bash
# Build:
docker build --tag hugo-site-ci .

# To validate the local development directory:
# docker run --mount type=bind,source=.,target=/source --rm cariad/hugo-site-ci
rm -rf build && mkdir build && docker run --mount type=bind,source=$(pwd),target=/source --mount type=bind,source=$(pwd)/build,target=/build --rm hugo-site-ci

# Interactive:
docker run -it --entrypoint /bin/bash --rm hugo-site-ci

```
