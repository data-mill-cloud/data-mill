# Data-Mill: Setup & Development

## 1. Infrastructure setup
* LOCATION: local (-l) to the node by installing minikube, remote (-r) to a VM or a Cluster
* ACTION: install (-i) the components or delete them (-d) using Helm
* CONFIG: the default config file for each component is config.yaml, -c [filename] to overwrite

```
Usage: ./run.sh [debug-mode] [params] [options]
  debug mode:
    DEBUG: -d
  params:
    LOCATION: -l (local), -r (remote)
    ACTION: -s (start only), -i (install), -u (uninstall)
  options:
    CONFIG: -f config_file_name.yaml
    COMPONENT: -c component_name
```

Components are stored at in the *components* subfolder. Each component consists of a setup.sh and a bunch of config_*.yaml files, possibly reflecting different environments or cluster setups.
The actual configuration file for the specific component is then referenced from therein, e.g.:

```
kafka:
  release: kafka
  config_file: kafka_config.yaml
```

The project-wide configuration is stored in the infrastructure root folder in config.yaml:
```
project:
  k8s_namespace: data-mill
  proxy_port: 8088
  flavour: all
```
The flavour indicates which components are to be included in the project the default is related to.
You can use `flavour: all` or list the component names e.g. `flavour: spark, jupyterhub`.

The projects is structured over the following folders:
* volumes - contains the persistent volumes and the persistent volume claims to be mounted at startup (e.g. to mount a partition with static files).
* data - is mounted as PV and PVC and eventually available in the Minio S3 data lake, it can be used to provide example code
* helm-charts - contains the code used to develop helm charts that were not available to us at time of development
* utils - contain bash utility functions (e.g. arg parsing)
* k8s - contain the cluster setup and configuration data

## 2. Common functions

### 2.1 Debugging environment
A debugging environment (i.e., a pod within the namespace providing an interactive session) can be spawned using `run.sh -d`.

### 2.2 Installing local helm charts
We provide a subfolder to collect a few helm-chart that were not yet offered at the time of development.   
To install a helm chart from the infrastructure folder you would normally run something like:
```
helm install --dry-run --debug --name mlflow-test --namespace data-mill helm-charts/mlflow/
helm install --name mlflow-test --namespace data-mill helm-charts/mlflow/
```
with the first command testing the chart and the second actually deploying it on the default data-mill namespace.

Alternatively, just add our Git Repo as Helm repo too:
```
helm repo add data-mill https://data-mill-cloud.github.io/data-mill/helm-charts/
```

## 3. Developing applications


## 4. Debugging utils

List containers running in each pod:
```
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort
```
