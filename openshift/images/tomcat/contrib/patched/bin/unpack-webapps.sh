#!/usr/bin/env bash
set -e

THIS_DIR="$(dirname $0)"
cd "$THIS_DIR"
cd ../
find ./webapps/ -maxdepth 1 -name '*.war' | xargs basename -s .war | xargs -t -I {} mkdir 'webapps/{}'
find ./webapps/ -maxdepth 1 -name '*.war' | xargs basename -s .war | xargs -t -I {} unzip -n -qq '/usr/local/tomcat/webapps/{}.war' -d 'webapps/{}'
find ./webapps/ -maxdepth 1 -name '*.war' | xargs -t -I {} rm '{}'
