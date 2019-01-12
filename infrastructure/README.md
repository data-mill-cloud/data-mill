# Data-Mill: Setup & Development

## 1. Infrastructure setup
* LOCATION: local (-l) to the node by installing minikube, remote (-r) to a VM or a Cluster
* ACTION: install (-i) the components or delete them (-d) using Helm
* CONFIG: the default config file for each component is config.yaml, -f [filename] defines a different project config file
* COMPONENT: runs the ACTION only for the specific component, regardless of the project flavour

```
Usage: ./run.sh [debug-mode] [params] [options]
  debug mode:
    DEBUG: -d
  params:
    LOCATION: -l (local cluster), -r (remote cluster)
    ACTION: -s (start only), -i (install), -u (uninstall)
  options:
    CONFIG_FILE: -f filename.yaml
      -> overwrites the default component configuration filename
    TARGET_FILE: -t filename.yaml
      -> overwrites the default k8s configuration filename
    COMPONENT: -c component_name
```

Components are stored at in the *components* subfolder. Each component consists of a setup.sh and a bunch of config_*.yaml files, possibly reflecting different environments or cluster setups.
The actual configuration file for the specific component is then referenced from therein, e.g.:

```
kafka:
  release: kafka
  config_file: kafka_config.yaml
```

The project-wide configuration is stored in the infrastructure flavours folder as `default.yaml`:
```
project:
  # namespace
  k8s_namespace: data-mill
  # the port on which the K8s UI is exposed
  proxy_port: 8088
  # the flavour is used to list all the components to be used in the project
  flavour: all
  # k8s default config, can be overwritten with -t filename
  k8s_default_config: default.yaml
  # component default config, can be overwritten with -f filename
  component_default_config: config.yaml
```

The flavour indicates which components are to be included in the project the default is related to.
You can use `flavour: all` or list the component names e.g. `flavour: spark, jupyterhub`.
When using `flavour: all` the components are taken in alphabetical order, so it is necessary to list them if you have dependencies across them.
The `k8s_default_config` is used to specify the default filename for cluster configuration, this can be overwritten with `-t filename`.
The `component_default_config` is used to specify the default configuration filename for each component, and can be overwritten with `-f filename`.
With `-f filename` we can specify a different flavour than the default one, and overwrite the config of each file (if `filename` exists, or fallback to `component_default_config` where it 
doesn't).

The projects is structured over the following folders:
* components - containing the installable components
* data - is mounted as PV and PVC and eventually available in the Minio S3 data lake, it can be used to provide example code
* flavours - where configurations are stored. A file define the project details, and a flavour, i.e. a group of components to be used in the project
* helm-charts - contains the code used to develop helm charts that were not available to us at time of development
* k8s - contains the cluster setup and configuration data
* registry - contains the details to manage a local docker registry
* utils - contains bash utility functions (e.g. arg parsing)

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
Please check the `data` folder for examples on how to connect to services, such as S3, Spark, Dask, Keras/Tensorflow.

## 4. Data versioning
Pachyderm is provided for code versioning purposes. This component is using the default minio datalake, where it creates a specific bucket.
The utility pachctl can be installed to interact with Pachyderm, see the guide [here](http://docs.pachyderm.io/en/latest/getting_started/local_installation.html), for instance:
Once pachctl is available, we can point it to the cluster's master node, or in case of a single node setup like minikube or mikrok8s to the sole node available:
```
export ADDRESS=$(minikube ip)":30650"
```
We can test the correct connection to the cluster by querying the version, for instance:
```
$ pachctl version
COMPONENT           VERSION
pachctl             1.8.2
pachd               1.7.3
```
This shows that both the client and server were correctly setup. You can now go on with the official tutorial, [here](https://pachyderm.readthedocs.io/en/latest/getting_started/beginner_tutorial.html).
The example below creates a new repo called images and lists its content, both before and after uploading an image from the web.
```
pachctl create-repo images
pachctl list-repo
pachctl put-file images master liberty.png -f http://imgur.com/46Q8nDz.png
pachctl list-repo
```

## 5. Debugging utils

List containers running in each pod:
```
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort
```
