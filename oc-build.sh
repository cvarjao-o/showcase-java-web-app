#!/usr/bin/env bash
set -e

function _oc {
  oc -n csnr-devops-lab-deploy "$@"
}

function _jq {
  arg_file="${@: -1}"
  tmp_input_file="$(dirname $arg_file)/_$(basename $arg_file)"
  cp $arg_file "${tmp_input_file}"
  jq "${@:1:$#-1}" "${tmp_input_file}" > "$arg_file"
  rm "${tmp_input_file}"
}

function _archive {
  for arg in "$@"; do
    case "$arg" in
      --file=*)
          rm -f "${arg#*=}"
        ;;
    esac
  done
  GZIP=-n gtar -cz --format=ustar --numeric-owner --no-acls --no-selinux --no-xattrs --owner=0 --group=0 --numeric-owner --mtime="2019-01-01 00:00Z" --dereference "$@"
}

function getImageStreamImageBySourceChecksum {
  local imageStreamImageName="$1"
  local sourceChecksum="$2"
  
  #echo "imageStreamImageName=${imageStreamImageName}"
  #echo "sourceChecksum=${sourceChecksum}"
  oc get "is/$imageStreamImageName" -o json | jq -rM '.status.tags[].items[].image' | while read -r line ; do
    local checksum=$(oc get "imagestreamimage/${imageStreamImageName}@${line}" -o json | jq -rM '.image.dockerImageMetadata.Config.Labels["input.source.checksum"]')
    #echo "'$checksum' == '$sourceChecksum' (${imageStreamImageName}@${line})?"
    if [ "$checksum" == "$sourceChecksum" ]; then
      echo "imagestreamimage/${imageStreamImageName}@${line}"
      break
    fi
  done

}

function _start_build_from_archive {
  local buildConfigName="$1"
  local sourceArchiveFile="$2"
  local buildConfigOutput="$(oc get "BuildConfig/$buildConfigName" -o json | jq -rcM '.spec.output.to')"
  local outputImageStreamName="$(jq -r '.name' <<< "$buildConfigOutput" | cut -d':' -f1)"
  local sourceArchiveFileChecksum="$(shasum -b $sourceArchiveFile | cut -d' ' -f1)"

  #echo "outputImageStreamName=${outputImageStreamName}"

  local matchImageStreamImage="$(getImageStreamImageBySourceChecksum "$outputImageStreamName" "$sourceArchiveFileChecksum")"
  #echo "matchImageStreamImage=${matchImageStreamImage}"

  _oc patch "BuildConfig/${buildConfigName}" -p '{"spec": {"output": {"imageLabels":[{"name":"input.source.checksum", "value":"'$sourceArchiveFileChecksum'"}]}}}' > /dev/null
  if [ "$matchImageStreamImage" != "" ]; then
    local outputImageStreamTag="$(jq -r '.name' <<< "$buildConfigOutput")"
    #echo "outputImageStreamTag='${outputImageStreamTag}'"
    echo "Reusing existing image from '${matchImageStreamImage}'"
    _oc tag "$(cut -d'/' -f2 <<< "$matchImageStreamImage")" "$(jq -r '.name' <<< "$buildConfigOutput")" --source=imagestreamimage --reference-policy='local' > /dev/null
  else
    echo "Starting new build"
    _oc start-build "${buildConfigName}" "--from-archive=${sourceArchiveFile}" --wait
  fi
}

function convert_list_to_build_template {
  #echo "Deleting BuildConfig.spec.triggers"
  _jq 'del(.items[] | select(.kind == "BuildConfig") | .spec.triggers[] | select(.type == "GitHub" or .type == "Generic" or .type == "ImageChange"))' "$1"

  #echo "Deleting ImageStreamTag"
  _jq 'del(.items[] | select(.kind == "ImageStreamTag"))' "$1"

  _jq '(.items[] | select(.kind == "BuildConfig" and .spec.strategy.dockerStrategy !=null)).spec.strategy.dockerStrategy.imageOptimizationPolicy |= "SkipLayers"' "$1"
  _jq '(.items[] | select(.kind == "BuildConfig" and .spec.strategy.sourceStrategy !=null)).spec.strategy.sourceStrategy.forcePull |= true' "$1"

  #echo "Updating ImageStream.spec.tags.referencePolicy.type to 'Local'"
  _jq '(.items[] | select(.kind == "ImageStream" and .spec.tags[0] !=null) | .spec.tags[].referencePolicy.type) |= "Local"' "$1"

  #echo "Removing superfluous labels and annotations"
  _jq 'del(.items[] | .metadata.labels.build)' "$1"
  _jq 'del(.items[] | .metadata.annotations["openshift.io/generated-by"])' "$1"

#  echo "Setting build environment variables"
#  _jq '(.items[] | select(.kind == "BuildConfig") | .spec.strategy.sourceStrategy).env |= [{"name": "S2I_SOURCE_DEPLOYMENTS_FILTER", "value":"*.war"}, {"name": "MAVEN_S2I_ARTIFACT_DIRS", "value":"target/"}, {"name": "MAVEN_CLEAR_REPO", "value":"true"}]' "$1"

  #echo "Setting build resources (requests + limits)"
  _jq '(.items[] | select(.kind == "BuildConfig") | .spec.resources) |= {"requests" : {"cpu": "1", "memory": "1Gi"}, "limits": {"cpu": "2", "memory": "2Gi"}}' "$1"

  #echo "Converting 'List' to 'Template'"
  _jq --arg name "$2" '.kind = "Template" | .objects = .items | del(.items) | .labels = {"template": $name}' "$1"
}

echo "Creating template: webapp-builder-build.json"
_oc new-build . --context-dir=openshift/images/_webapp --name=webapp-builder --dry-run -o json > openshift/templates/webapp-builder-build.json
convert_list_to_build_template openshift/templates/webapp-builder-build.json 'showcase-java-web-app'

# oc run maven --image=docker-registry.default.svc:5000/csnr-devops-lab-deploy/webapp-builder:latest -it --rm --restart=Never --image-pull-policy=Always --command -- bash

echo "Applying template: webapp-builder-build.json"
_archive --file=source.tar.gz  openshift/images/_webapp
_oc process -f openshift/templates/webapp-builder-build.json | _oc apply -f -
_start_build_from_archive webapp-builder source.tar.gz

echo "Creating template: webapp-build.json"
_oc new-build webapp-builder:latest~. --name=showcase-java-web-app '--env=S2I_SOURCE_DEPLOYMENTS_FILTER=*.war' '--env=MAVEN_S2I_ARTIFACT_DIRS=target/' '--env=MAVEN_CLEAR_REPO=true' '--env=MAVEN_ARGS=--offline' --dry-run -o json > openshift/templates/webapp-build.json
convert_list_to_build_template openshift/templates/webapp-build.json 'showcase-java-web-app'


echo "Applying template: webapp-builder-build.json"
_oc process -f openshift/templates/webapp-build.json | _oc apply -f -
_archive --file=source.tar.gz pom.xml src/main
_start_build_from_archive showcase-java-web-app source.tar.gz


echo "Creating template: tomcat-build.json"
_oc new-build . --context-dir=openshift/images/tomcat --name=showcase-tomcat --strategy=docker --dry-run -o json > openshift/templates/tomcat-build.json
convert_list_to_build_template openshift/templates/tomcat-build.json 'showcase-java-web-app'

echo "Applying template: tomcat-build.json"
_oc process -f openshift/templates/tomcat-build.json | _oc apply -f -
_archive '--file=source.tar.gz' --exclude=openshift/images/tomcat/contrib/original --exclude=openshift/images/tomcat/contrib/patched openshift/images/tomcat
_start_build_from_archive showcase-tomcat source.tar.gz

echo "Creating template: webapp-build-final.json"
oc new-build --image-stream=showcase-tomcat:latest --name=showcase-java-web-app-final --source-image=showcase-java-web-app:latest --source-image-path=/deployments:. --to=showcase-java-web-app-final:latest --strategy=docker -D $'FROM showcase-tomcat:latest\nCOPY deployments/showcase-java-web-app.war /usr/local/tomcat/webapps/ROOT.war\nRUN find /usr/local/tomcat/webapps/ -maxdepth 1 -name "*.war" | xargs basename -s .war | xargs -t -I {} mkdir "/usr/local/tomcat/webapps/{}" && \ \n  find /usr/local/tomcat/webapps/ -maxdepth 1 -name "*.war" | xargs basename -s .war | xargs -t -I {} unzip -n -qq "/usr/local/tomcat/webapps/{}.war" -d "/usr/local/tomcat/webapps/{}" && \ \n  find /usr/local/tomcat/webapps/ -maxdepth 1 -name "*.war" | xargs -t -I {} rm "{}" && \ \n  ls -la /usr/local/tomcat/webapps/ROOT/' --dry-run -o json > openshift/templates/webapp-build-final.json
convert_list_to_build_template openshift/templates/webapp-build-final.json 'showcase-java-web-app'

echo "Applying template: webapp-build-final.json"
_oc process -f openshift/templates/webapp-build-final.json | _oc apply -f -
_oc start-build showcase-java-web-app-final --wait
