# Data-Mill: Setup & Development

## 1. Infrastructure setup
* LOCATION: local (-l) to the node by installing minikube, remote (-r) to a VM or a Cluster
* ACTION: install (-i) the components or delete them (-d) using Helm
* CONFIG: the default config file for each component is config.yaml, -c [filename] to overwrite

```
Usage: ./setup.sh [params] [mass-args]
  params:
    LOCATION: -l (local), -r (remote)
    ACTION: -i (install), -d (delete)
  options:
    CONFIG: -c config_file_name.yaml
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
```

The projects is structured over the following folders:
* volumes - contains the persistent volumes and the persistent volume claims to be mounted at startup (e.g. to mount a partition with static files).
* data - is mounted as PV and PVC and eventually available in the Minio S3 data lake, it can be used to provide example code
* utils - contain bash utility functions (e.g. arg parsing)
* k8s - contain the cluster setup and configuration data

## 2. Common functions

## 3. Developing applications
