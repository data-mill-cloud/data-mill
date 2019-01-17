# K8s Setup
This folder contains the details of the Kubernetes (K8s) cluster and its setup script.

## 1. Local setup
We provide a means for setting up a local Kubernetes cluster using Minikube and Microk8s.

### 1.1 Minikube
An example configuration file for minikube is reported below:

```
local:
  cpus: 8
  memory: 16288
  storage: 60G
  gpu_support: true
  use_overlay: false
  provider: minikube
  vm_driver: kvm2
```

### 1.2 MicroK8s
An example configuration file for microk8s is reported below:
```
local:
  cpus: 8
  memory: 16288
  storage: 60G
  gpu_support: true
  use_overlay: false
  provider: microk8s
```
Microk8s can be installed either directly using snap (e.g. on Ubuntu/Debian distros) or using a Multipass VM.
Mind that when using Multipass the GPU support is not available.

## 2. Remote setup
We provide basic scripts for the setup of AWS and GKE K8s clusters, using the Kubernetes operations (KOPS) tool.
For this setup, a configuration file for AWS would look like the following:
```
remote:
  type: aws
  cluster_name: data-mill
  bucket_name: data-mill
  region: "us-east1"
  zones: "us-east1a"
  no_nodes: 2
  node_size: t2.medium
```
