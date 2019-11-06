#!/usr/bin/env bash
set -e

THIS_DIR="$(dirname $0)"
cd "$THIS_DIR"
THIS_DIR="$(pwd)"

function _oc {
  oc -n csnr-devops-lab-deploy "$@"

}

function _waitUntilPodIsReady {
  local ready='False'
  echo "Waiting for pod/$1"
  while [ "$ready" != 'True' ]; do
    sleep 1
    ready="$(_oc get "pod/$1" --ignore-not-found -o json | jq -rcM '.status.conditions[] | select(.type == "Ready").status')"
  done
}

_oc delete pod/tomcat --now --wait --ignore-not-found=true
_oc run tomcat --image=tomcat:9.0.27-jdk8-openjdk -it --restart=Never --image-pull-policy=Always --command -- bash &>/dev/null &
_waitUntilPodIsReady tomcat

for file in "bin/catalina.sh" "conf/server.xml" "conf/web.xml" ; do
  mkdir -p "${THIS_DIR}/contrib/original/$(dirname $file)"
  mkdir -p "${THIS_DIR}/contrib/patched/$(dirname $file)"
  _oc cp "tomcat:/usr/local/tomcat/$file" "${THIS_DIR}/contrib/original/${file}" &> /dev/null
done
_oc delete pod/tomcat --now --wait --ignore-not-found=true

./patch-from-original.sh
