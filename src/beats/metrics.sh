#!/usr/bin/env bash

echo $0
echo $(dirname $0)

./metricbeat-7.4.2-darwin-x86_64/metricbeat run -e -c ./metric/conf/metricbeat.yml