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

function convert_list_to_deployment_template {
  _jq 'del(.items[] | select(.kind == "DeploymentConfig") | .spec.selector.app)' "$1"
  _jq 'del(.items[] | select(.kind == "Service") | .spec.selector.app)' "$1"

  #echo "Removing superfluous labels and annotations"
  _jq 'del(.items[] | .metadata.labels.app)' "$1"
  _jq 'del(.items[] | .metadata.annotations["openshift.io/generated-by"])' "$1"
  _jq 'del(.items[] | .spec.template.metadata.labels.app)' "$1"
  _jq 'del(.items[] | .spec.template.metadata.annotations["openshift.io/generated-by"])' "$1"

  #echo "Converting 'List' to 'Template'"
  _jq --arg name "$2" '.kind = "Template" | .objects = .items | del(.items) | .labels = {"template": $name}' "$1"
}

echo "Creating template: showcase-java-webapp-deploy.json"
_oc new-app --image-stream=showcase-java-web-app-final:latest --name=showcase-java-web-app --dry-run -o json > openshift/templates/webapp-deploy.json
convert_list_to_deployment_template openshift/templates/webapp-deploy.json showcase-java-web-app
_jq '.objects += [{"kind":"Route","apiVersion":"route.openshift.io/v1","metadata":{"name":"showcase-java-web-app","creationTimestamp":null,"labels":{}},"spec":{"host":"","to":{"kind":"Service","name":"showcase-java-web-app","weight":100},"port":{"targetPort":"8080-tcp"},"tls":{"termination":"edge"}},"status":{"ingress":null}}]' openshift/templates/webapp-deploy.json
_jq '.objects += [{"apiVersion":"v1","kind":"ServiceAccount","metadata":{"creationTimestamp":null,"name":"showcase-java-web-app"}}]' openshift/templates/webapp-deploy.json
_jq '.objects += [{"apiVersion":"rbac.authorization.k8s.io/v1","kind":"Role","metadata":{"name":"showcase-java-web-app"},"rules":[{"apiGroups":[""],"resources":["pods"],"verbs":["get","watch","list"]}]}]' openshift/templates/webapp-deploy.json
_jq '.objects += [{"apiVersion":"rbac.authorization.k8s.io/v1","kind":"RoleBinding","metadata":{"creationTimestamp":null,"name":"showcase-java-web-app"},"roleRef":{"apiGroup":"rbac.authorization.k8s.io","kind":"Role","name":"showcase-java-web-app"},"subjects":[{"kind":"ServiceAccount","name":"showcase-java-web-app"}]}]' openshift/templates/webapp-deploy.json
_jq '(.objects[] | select(.kind == "DeploymentConfig" and .metadata.name == "showcase-java-web-app").spec.template.spec).serviceAccountName = "showcase-java-web-app"' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig" and .metadata.name == "showcase-java-web-app").spec).replicas = 3' openshift/templates/webapp-deploy.json
_jq '(.objects[] | select(.kind == "DeploymentConfig" and .metadata.name == "showcase-java-web-app").spec).minReadySeconds = 300' openshift/templates/webapp-deploy.json
_jq '(.objects[] | select(.kind == "DeploymentConfig" and .metadata.name == "showcase-java-web-app").spec).strategy = {"type":"Rolling", "activeDeadlineSeconds":21600, "rollingParams":{"maxUnavailable":1, "maxSurge":3, "intervalSeconds":1, "timeoutSeconds": 600, "updatePeriodSeconds": 1}}' openshift/templates/webapp-deploy.json
_jq '(.objects[] | select(.kind == "DeploymentConfig" and .metadata.name == "showcase-java-web-app").spec.template.spec).containers[0].env += [{"name":"OPENSHIFT_KUBE_PING_NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}},{"name":"OPENSHIFT_KUBE_PING_LABELS","value":"deploymentconfig=showcase-java-web-app"},{"name":"CATALINA_OPTS","value":"-Djava.security.egd=file:/dev/./urandom"}]' openshift/templates/webapp-deploy.json 

_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec).containers += [{"name":"filebeat", "image":" ", "command":["/usr/local/tomcat/filebeat/filebeat", "run", "--e", "-c", "/usr/local/tomcat/conf/filebeat.yml", "-E", "output.console.enabled=false", "-E", "output.elasticsearch.hosts=['https://security-master:9200']", "-E", "output.elasticsearch.username='elastic'", "-E", "output.elasticsearch.password='cEFtS5H5Hxv7MNotplorGk'", "-E", "output.elasticsearch.ssl.verification_mode='none'"]}]' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec).containers += [{"name":"metricbeat", "image":" ", "command":["/usr/local/tomcat/metricbeat/metricbeat", "run", "--e", "-c", "/usr/local/tomcat/conf/metricbeat.yml", "-E", "output.console.enabled=false", "-E", "output.elasticsearch.hosts=['https://security-master:9200']", "-E", "output.elasticsearch.username='elastic'", "-E", "output.elasticsearch.password='cEFtS5H5Hxv7MNotplorGk'", "-E", "output.elasticsearch.ssl.verification_mode='none'"]}]' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[]).imagePullPolicy = "Always"' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec).volumes = [{"name":"access-logs", "emptyDir":{}}, {"name":"conf", "emptyDir":{}}]' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec).initContainers = [{"name":"copy-filebeat-conf", "image":" ", "command":["cp", "/usr/local/tomcat/conf/filebeat.yml", "/mnt/conf/"], "volumeMounts":[{"name":"conf", "mountPath":"/mnt/conf"}]}]' openshift/templates/webapp-deploy.json
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "showcase-java-web-app")).ports += [{"name":"jolokia", "protocol":"TCP", "containerPort":7070}]' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "showcase-java-web-app")).readinessProbe = {"failureThreshold":3,"httpGet":{"path":"/info","port":8080,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":2,"successThreshold":3,"timeoutSeconds":2}' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "showcase-java-web-app")).volumeMounts = [{"name":"access-logs", "mountPath":"/usr/local/tomcat/logs"}]' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "showcase-java-web-app")).resources = {"requests": {"cpu":"100m", "memory":"192Mi"}, "limits": {"memory": "256Mi", "cpu":"500m"}}' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "filebeat")).volumeMounts = [{"name":"access-logs", "mountPath":"/usr/local/tomcat/logs"}]' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.triggers[] | select(.type == "ImageChange" and .imageChangeParams.containerNames[0] == "showcase-java-web-app")).imageChangeParams.containerNames += ["copy-filebeat-conf", "filebeat", "metricbeat"]' openshift/templates/webapp-deploy.json 



_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "showcase-java-web-app")).terminationGracePeriodSeconds = 120' openshift/templates/webapp-deploy.json 
_jq '(.objects[] | select(.kind == "DeploymentConfig").spec.template.spec.containers[] | select(.name == "showcase-java-web-app")).lifecycle = {"preStop": {"exec": {"command":["kill", "-15", "1"]}}}' openshift/templates/webapp-deploy.json 

echo "Applying template: webapp-deploy.json"
_oc create -f openshift/templates/webapp-deploy.json --dry-run -o yaml > openshift/templates/webapp-deploy.yaml
#_oc process -f openshift/templates/webapp-deploy.json | _oc apply -f -
