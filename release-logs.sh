#!/usr/bin/env bash

set -euo pipefail

usage="helm release-logs <release> [options]"
function usage() {
  echo "Usage: ${usage}"
  exit 1
}

function help() {
  echo "A Helm plugin to get debug information about the Kubernetes resources creaeted by a release."
  echo "The output is useful for troubleshooting in a CI / CD environment where it is valuable to"
  echo "capture the state of a release following a failure. The following information will be output"
  echo "to the output directory."
  echo
  echo "* Environment variables"
  echo "* Helm release list"
  echo "* Helm user values"
  echo "* Helm computed values"
  echo "* Kubernetes resource list"
  echo "* Kubernetes describe of each pod"
  echo "* Kubernetes logs for each container"
  echo
  echo "Usage: ${usage}"
  echo
  echo "-h|--help       show this help message"
  echo "-n|--namespace  namespace the release is installed to [default: \$HELM_NAMESPACE]"
  echo "-d|--dir        output directory for logs, created if it doesn't exist [default: ./logs]"

  exit 0
}


namespace="${HELM_NAMESPACE}"
dir="./logs"

args=()
while [[ ${#} -gt 0 ]]; do
  case ${1} in
    -h|--help)
      help
      ;;
    -n|--namespace)
      namespace="${2}"
      shift
      shift
      ;;
    -d|--dir)
      dir="${2}"
      shift
      shift
      ;;
    *)
      args+=("${1}")
      shift
  esac
done

if [[ ${#args[@]} -ne 1 ]]; then
  usage
  echo "Error: invalid release argument"
  exit 1
fi
release="${args[0]}"

helm="${HELM_BIN} -n ${namespace}"
kubectl="kubectl -n ${namespace}"

mkdir -p "${dir}/pod"

echo "Gathering info for release ${release} in namespace ${namespace} ..."

echo "Saving environment variables ..."
env | grep -v PASS | sort > "${dir}/env"

echo "Saving Helm release list ..."
${helm} ls > "${dir}/releases.log" || true

echo "Saving Helm user values ..."
${helm} get values "${release}" > "${dir}/values-user.yaml" || true

echo "Saving Helm computed values ..."
${helm} get values "${release}" --all > "${dir}/values-computed.yaml" || true

echo "Saving Kubernetes resource list ..."
${helm} get manifest "${release}" | ${kubectl} get -o wide -f - > "${dir}/resources.log" || true

for pod in $(${kubectl} get pods -o name); do
  echo "Saving describe output for ${pod}"
  ${kubectl} describe ${pod} > "${dir}/${pod}.describe.log" || true
  
  for container in $(${kubectl} get ${pod} -o json | jq -r '.spec.initContainers[]?.name'); do
    echo "Saving logs for init container ${container} in pod ${pod}"
    ${kubectl} logs ${pod} -c ${container} > "${dir}/${pod}_${container}.log" || true
  done
  
  for container in $(${kubectl} get ${pod} -o json | jq -r '.spec.containers[]?.name'); do
    echo "Saving logs for container ${container} in pod ${pod}"
    ${kubectl} logs ${pod} -c ${container} > "${dir}/${pod}_${container}.log" || true
  done
done
