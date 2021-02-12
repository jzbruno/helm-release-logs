# Helm Release Logs Plugin

## Overview

A Helm plugin to get debug information about the Kubernetes resources creaeted by a release. The output is useful for troubleshooting in a CI / CD environment where it is valuable to capture the state of a release following a failure. The following information will be output to the output directory.

For best results, it is recommended that your Helm chart specifies a metadata.namespace value for each resource (even if it just the chart default of `{{ .Release.Namespace }}`). The plugin uses the output of `helm get manifest` and `helm get hooks` to determine the resources available for log collection.

* Environment variables
* Helm release list
* Helm user values
* Helm computed values
* Kubernetes resource list
* Kubernetes describe of each pod
* Kubernetes logs for each container

## Requirements

* Helm v3
* Kubectl
* jq

## Install

```bash
helm plugin install https://github.com/jzbruno/helm-release-logs/
```

## Usage

```bash
helm release-logs <release>
helm release-logs -h
```
