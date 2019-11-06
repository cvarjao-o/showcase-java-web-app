FROM tomcat:9.0.27-jdk8-openjdk
ARG LOG4J_VERSION=2.12.1
COPY contrib/tomcat.patch /usr/local/tomcat/
COPY contrib/tomcat.sha1 /usr/local/tomcat/
RUN set -xe && \
    apt-get update -qq && \
    apt-get install -qq -y --no-upgrade patch && \
    rm -rf /usr/local/tomcat/webapps/* && \
    mkdir -p /usr/local/tomcat/conf/Catalina/localhost && \
    chmod g+w /usr/local/tomcat/conf/Catalina/localhost && \
    chmod g+w /usr/local/tomcat/webapps && \
    ( cd /usr/local/tomcat && sha1sum --check /usr/local/tomcat/tomcat.sha1 --status) && \
    patch --batch --forward --unified  --strip=1 --directory=/usr/local/tomcat --input=/usr/local/tomcat/tomcat.patch && \
    mkdir -p /usr/local/tomcat/log4j/lib /usr/local/tomcat/log4j/conf && \
    curl -sSL https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/$LOG4J_VERSION/log4j-api-$LOG4J_VERSION.jar -o /usr/local/tomcat/log4j/lib/log4j-api-$LOG4J_VERSION.jar && \
    curl -sSL https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/$LOG4J_VERSION/log4j-core-$LOG4J_VERSION.jar -o /usr/local/tomcat/log4j/lib/log4j-core-$LOG4J_VERSION.jar && \
    curl -sSL https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-appserver/$LOG4J_VERSION/log4j-appserver-$LOG4J_VERSION.jar -o /usr/local/tomcat/log4j/lib/log4j-appserver-$LOG4J_VERSION.jar && \
    rm /usr/local/tomcat/conf/logging.properties && \
    curl -sSL https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.4.2-linux-x86_64.tar.gz -o /tmp/filebeat.tar.gz && \
    mkdir -p /usr/local/tomcat/filebeat && \
    mkdir -p /usr/local/tomcat/filebeat/data && \
    chmod g+rw /usr/local/tomcat/filebeat/data && \
    mkdir -p /usr/local/tomcat/filebeat/logs && \
    chmod g+rw /usr/local/tomcat/filebeat/logs && \
    tar -xvf /tmp/filebeat.tar.gz -C /usr/local/tomcat/filebeat/ --strip-components 1 && \
    chgrp -R 0 /usr/local/tomcat/filebeat && \
    curl -sSL https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-7.4.2-linux-x86_64.tar.gz -o /tmp/metricbeat.tar.gz && \
    mkdir -p /usr/local/tomcat/metricbeat && \
    tar -xvf /tmp/metricbeat.tar.gz -C /usr/local/tomcat/metricbeat/ --strip-components 1 && \
    mkdir -p /usr/local/tomcat/metricbeat/data && \
    chmod g+rw /usr/local/tomcat/metricbeat/data && \
    mkdir -p /usr/local/tomcat/metricbeat/logs && \
    chmod g+rw /usr/local/tomcat/metricbeat/logs && \
    chgrp -R 0 /usr/local/tomcat/metricbeat && \
    curl -sSL https://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar -o /usr/local/tomcat/bin/jolokia-jvm-1.6.2-agent.jar && \
    apt-get remove -qq -y --purge patch && apt-get clean && set +x && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*
