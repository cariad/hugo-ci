FROM ubuntu:20.04

ENV LC_ALL C.UTF-8

RUN apt-get update                                                && \
    apt-get --no-install-recommends --yes install dumb-init=1.2.* && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update                                  && \
    apt-get --no-install-recommends --yes install      \
      build-essential=12.8ubuntu*                      \
      libcurl4-openssl-dev=7.68.*                      \
      ruby-full=1:2.7+*                                \
      zlib1g-dev=1:1.2.*                            && \
    rm -rf /var/lib/apt/lists/*                     && \
    gem update --development --system --no-document

ENV HTMLPROOFER_VERSION 3.18.2
RUN gem install html-proofer:"${HTMLPROOFER_VERSION:?}" --no-document

ENV HUGO_VERSION 0.79.1
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz /tmp/hugo.tar.gz
RUN tar xzf /tmp/hugo.tar.gz --directory /usr/local/bin hugo && \
    rm /tmp/hugo.tar.gz                                      && \
    hugo version

ENV S3HEADERSETTER_VERSION 0.2.0
ADD https://github.com/cariad/s3headersetter/releases/download/v0.2.0/s3headersetter-linux-amd64.zip /tmp/s3hs.zip
RUN apt-get update                                            && \
    apt-get --no-install-recommends --yes install unzip=6.0-* && \
    rm -rf /var/lib/apt/lists/*                               && \
    unzip -q /tmp/s3hs.zip -d /tmp                            && \
    mv /tmp/s3headersetter /usr/local/bin/                    && \
    rm -rf /tmp/*

RUN apt-get update                                && \
    apt-get --no-install-recommends --yes install    \
      gpg=2.2.*                                      \
      gpg-agent=2.2.*                             && \
    rm -rf /var/lib/apt/lists/*

COPY keys/aws-cli.pub /tmp/aws-cli.pub
RUN gpg --import /tmp/aws-cli.pub && \
    rm -rf /tmp/*

ENV AWS_VERSION 2.1.13
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VERSION}.zip     /tmp/aws.zip
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VERSION}.zip.sig /tmp/aws.zip.sig
RUN gpg --verify /tmp/aws.zip.sig /tmp/aws.zip && \
    unzip /tmp/aws.zip -d /tmp                 && \
    /tmp/aws/install                           && \
    rm -rf /tmp/*                              && \
    aws --version

COPY config/ /config
COPY bin/    /usr/local/bin

ENTRYPOINT ["dumb-init", "entrypoint.sh"]
