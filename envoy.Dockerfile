FROM envoyproxy/envoy-dev:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
    && apt-get -qq install --no-install-recommends -y curl \
    && apt-get -qq autoremove -y \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*


CMD [ "/usr/local/bin/envoy", "--log-level", "trace", "-c", "/etc/envoy.yml" ]
