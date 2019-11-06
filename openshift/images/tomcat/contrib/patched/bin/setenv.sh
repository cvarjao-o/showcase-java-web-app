CLASSPATH="$CATALINA_HOME/log4j/lib/*:$CATALINA_HOME/log4j/conf"
# Reserve 10MB from the available memory
CATALINA_OPTS="-Xmx40M $CATALINA_OPTS"
CATALINA_OPTS="-XshowSettings:vm  -XX:MaxRAM=$(( $(cat /sys/fs/cgroup/memory/memory.limit_in_bytes) - ( 1024 * 10) )) -XX:MaxRAMPercentage=100.0 $CATALINA_OPTS"
CATALINA_OPTS="-javaagent:$CATALINA_HOME/bin/jolokia-jvm-1.6.2-agent.jar=port=7070,host=localhost,discoveryEnabled=false $CATALINA_OPTS"
