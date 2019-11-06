FROM registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:1.7-5
USER 0
COPY contrib/src /tmp/src
#RUN mkdir -p /var/cache/m2 && chmod g=u /var/cache/m2
RUN chgrp -R 0 /tmp/src && chmod -R g=u /tmp/src
USER 185
#COPY contrib/src /tmp/src
RUN source scl_source enable rh-maven35 && \
    (cd /tmp/src && mvn -B -e -Dmaven.repo.local=/tmp/artifacts/m2 package)
USER 0
RUN rm -rf /tmp/src
USER 185
