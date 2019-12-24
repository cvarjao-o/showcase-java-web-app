FROM fedora:30

ARG OC_VERSION=v3.11.0
ARG OC_QUALIFIER=0cbc58b-linux-64bit

RUN yum install git jq -y && \
    mkdir /workdir && \
    chgrp -R 0 /workdir && \
    chmod -R g=u /workdir

# Install OC
RUN set -x && \
    curl -sSL https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_QUALIFIER}.tar.gz -o /tmp/oc.tar.gz && \
    tar -xzf /tmp/oc.tar.gz -C /usr/local/bin  --strip-components=1  openshift-origin-client-tools-${OC_VERSION}-${OC_QUALIFIER}/oc openshift-origin-client-tools-${OC_VERSION}-${OC_QUALIFIER}/kubectl && \
    rm -rf /tmp/*

VOLUME /workdir
WORKDIR /workdir
