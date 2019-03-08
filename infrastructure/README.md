# Data-Mill: Setup & Development

## 1. Infrastructure setup
* LOCATION: local (-l) to the node by installing minikube, remote (-r) to a VM or a Cluster
* ACTION: install (-i) the components or delete them (-d) using Helm
* FLAVOUR_FILE: the default config file for each component is config.yaml, -f [filename] defines a different project config file (aka flavour)
* COMPONENT: runs the ACTION only for the specific component, regardless of the project flavour

```
Usage: ./run.sh [debug-mode] [params] [options]
  debug mode:
    DEBUG: -d
  params:
    LOCATION: -l (local cluster), -r (remote cluster)
    ACTION: -s (start only), -i (install), -u (uninstall)
    FLAVOUR_FILE: -f path/filename.yaml
      -> sets the project flavour file
  options:
    TARGET_FILE: -t path/filename.yaml
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
  k8s_default_config: default_uc.yaml
  # component default config, can be overwritten with -f filename
  component_default_config: config.yaml
  # set the data folder
  data_folder: data
```

The flavour attribute indicates which components are to be included in the project the default is related to.
You can use `flavour: all` or list the component names e.g. `flavour: spark, jupyterhub`.
When using `flavour: all` the components are taken in alphabetical order, so it is necessary to list them if you have dependencies across them.
The `k8s_default_config` is used to specify the default filename for cluster configuration, this can be overwritten with `-t filename`.
For instance, `default_uc.yaml` in `k8s/configs` specifies a microk8s cluster. This target can be overwritten with `-t` or directly in the flavour file, for instance using `default_mc.yaml` to target a minikube cluster.
The `component_default_config` is used to specify the default configuration filename for each component, and can be overwritten with `-f filename`.
With `-f filename` we can specify a different flavour than the default one, and overwrite the config of each file (if `filename` exists, or fallback to `component_default_config` where it 
doesn't). The data folder is where the code examples are stored, along with the bucket structure that we want replicated to the local datalake.

The component configuration can either be placed in the flavour folder on in the component folder.  
It is also important to explain how the flavour-specific configuration can be organized, namely in 3 modes:  
1. a folder is created for a specific flavour, to contain the project configuration (flavour config), the target (commonly included in the flavour, can be made external to distinguish multiple environments), a bunch of `values.yaml` files for the components that 
use it.  
2. a folder is used to contain all project configurations (for all flavours) and a `project.config_folder` property is defined to link to a specific folder where to retrieve the `values.yaml` files for the components that use it.  
3. none of the previous two, the file is neither available in the flavour folder nor a specific `config_folder` was set; the default `values.yaml` is used for the component from its folder.  

![Organizing flavours](https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/flavour_modes.png)

The projects is structured over the following folders:
* components - containing the installable components
* data - is mounted as PV and PVC and eventually available in the Minio S3 data lake, it can be used to provide example code
* flavours - where configurations are stored. A file define the project details, and a flavour, i.e. a group of components to be used in the project
* helm-charts - contains the code used to develop helm charts that were not available to us at time of development
* k8s - contains the cluster setup and configuration data
* registry - contains the details to manage a local docker registry
* utils - contains bash utility functions (e.g. arg parsing)

## 2. Example flavours

The components were successfully tested on all 3 local environments and a few example flavours are provided to get quickly started:
* default - installs all components in alphabetical order, which can be highly memory consuming so use with caution
* datalake_flavour - installs the minio S3 and pachyderm to set up a datalake; this is the smallest flavour concerning pachyderm and a datalake;
* kubeflow_flavour - installs minio, pachyderm and kubeflow (using ksonnet), the integration of kubeflow was successfully tested, however we suggest installing kubeflow in a separated namespace (i.e. see the config for the component and the README) since upon 
* deletion using the default kfctl the entire namespace is deleted
* datawarehouse_flavour - installs minio, pachyderm, kafka, rabbitmq, superset, spark and the monitoring-stack.
* explorative_flavour - installs minio, arangodb, influxdb, superset, jupyterhub, dask and seldon.

An example flavour is reported below:   
![Example flavour](https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/architecture.png)

## 3. Common functions

### 3.1 Start existing cluster
An existing cluster can be started as follows:
```
./run.sh -l -s -f flavours/default.yaml
```
This will use the default flavour and k8s config (i.e. `k8s_default_config: default_uc.yaml`) to start the microk8s cluster defined in `default_uc.yaml`, without altering (installing/uninstalling) any component.  
To overwrite this behavior a different flavour can be passed with `-f flavour_config.yaml` or a different target file `-t target_config.yaml` can be set.

### 3.2 Debugging environment
A debugging environment (i.e., a pod within the namespace providing an interactive session) can be spawned using `run.sh -d`.

### 3.3 Installing local helm charts
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

### 3.4 Accessing the Data Lake and Data versioning
We use minio as local S3 datalake service. Code examples are directly copied to the minio pod and exposed as a bucket.
Within the cluster, Minio can be accessed at <minio-release>.<namespace>.svc.cluster.local on port 9000 (or http://<minio-release>:9000).
Minio can also be managed from it minio/mc client, using port forwarding to the pod:
```
export POD_NAME=$(kubectl get pods --namespace <namespace> -l "release=<minio-release>" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 9000 --namespace <namespace>
```
You can follow [this guide](https://docs.minio.io/docs/minio-client-quickstart-guide) to install the mc client. For instance:
```
mc config host add <ALIAS> <YOUR-S3-ENDPOINT> <YOUR-ACCESS-KEY> <YOUR-SECRET-KEY> <API-SIGNATURE>
```
Now we can manage the objects on the datalake, for instance create (`mc mb minio/mybucket`), list (`mc ls minio/mybucket`), delete (`mc rm minio/mybucket/myfile`).

Pachyderm is provided for code versioning purposes. This component is using the default minio datalake, where it creates a specific bucket.
The utility pachctl can be installed to interact with Pachyderm, see the guide [here](http://docs.pachyderm.io/en/latest/getting_started/local_installation.html).
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

## 4. Data Science Environments
Jupyterhub is a multi-user server that can be used to spawn multiple jupyter servers with different computation requirements and runtime environments.  
As visible and discussed [here](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html), there exists 3 main streams for the DS environments:
* `scipy-notebook` is the base Python DS Environment, as this includes the entire scientific python, if you rather develop in R the `r-notebook` is to be used; alternatively, the `datascience-notebook` is a heavy DS environment that contains libs for Python, R, 
Julia and a bunch of datasets and libraries;
* `pyspark-notebook` is the extension of the Python DS to add the Spark Python libraries, this is further extended in the all-spark-notebook with R and Scala support;
* `tensorflow-notebook` is the extension of the Python DS environment to add tensorflow and Keras support; mind that this runs on CPU resources only;
That said, we provide the following extensions:
* `python_env` extending `jupyter/scipy-notebook:latest`
* `pyspark_env` extending `jupyter/pyspark-notebook:latest`
* `pydl_env` extending `jupyter/tensorflow-notebook:latest`
* `pydl_gpu_env` extending `nvidia/cuda:9.0-base-ubuntu16.04` to add the whole jupyterhub stack as in the pydl_env;
* `gcr.io/kubeflow-images-public/tensorflow-1.10.1-notebook-gpu:v0.4.0` the standard GPU notebook image used in Kubeflow
The images were pushed to [Dockerhub](https://hub.docker.com/search?q=datamillcloud&type=image) and are automatically prepulled at deployment time using the prepuller hook of Jupyterhub. This can generate latencies during installation.
If you use wait in the helm install (i.e. --timeout $cfg__jhub__setup_timeout --wait), a good practice is to set jupyterhub as the last component installed in the flavour list.

## 5. Developing applications
Please check the `data` folder for examples on how to connect to services, such as S3, Spark, Dask, Keras/Tensorflow.

### 5.1 Connecting to the data lake
Connecting to the data lake can be done using the s3fs library, for instance:
```
import s3fs
s3 = s3fs.S3FileSystem(key='Ae8rNrsv8GoB4TUEZidFBzBp',
                       secret='2bd1769fa235373922229d65114a072',
                       client_kwargs={"endpoint_url":'http://minio-datalake:9000'})
```

### 5.2 Processing with Dask
When using Dask, a scheduler and multiple workers are spawned in the cluster. Dask distributed is provided as client to connect to the scheduler, e.g.:
```
from dask.distributed import Client, progress
c = Client("dask-scheduler:8786")
```

### 5.3 Processing with Spark
When developing Spark code, the provided pyspark notebook shall be used. A Spark session can be easily created with:
```
import pyspark
sc = pyspark.SparkContext('local[*]')
```
The Spark component is deployed as Kubernetes operator. That means that the code won't be runnable using the classic spark-submit to submit the 
job to an always running driver pod (for that you could rather run this instead of an operator), but rather spawned as any K8s resource (i.e. with `kubectl apply -f resource_config.yaml`), 
as shown in the example [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/quick-start-guide.md#running-the-examples), the guide [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md).
The pi application would be something like:
```
apiVersion: sparkoperator.k8s.io/v1beta1
kind: SparkApplication
metadata:
  name: spark-pi
  namespace: default
spec:
  type: Scala
  mode: cluster
  image: gcr.io/spark/spark:v2.4.0
  mainClass: org.apache.spark.examples.SparkPi
  mainApplicationFile: local:///opt/spark/examples/jars/spark-examples_2.11-2.4.0.jar
```

### 5.4 Processing with Keras & Tensorflow
We refer to our [code example](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/data/examples/keras_example.ipynb), showing the use of autoencoders for noise removal on image data (MNIST).

## 6. GPU Support
To enable GPU support you either set minikube/multipass VM to use a spare GPU or enable PCI passthrough, though this is currently only working for the bare microk8s version (I guess for license reasons on multipass).

## 7. Debugging utils

List containers running in each pod:
```
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort
```
Log specific container in a pod:
```
kubectl logs -n=<namespace> <pod-name> -c <container-name>
```

Get configuration being ran in a pod:
```
kubectl get pod -n=<namespace> <pod-name> -o=yaml
```

Retrieve the secrets used for the datalake:
```
$(kubectl -n <namespace> get secrets <minio-deployment> -o jsonpath="{.data.accesskey}" | base64 -d)
$(kubectl -n <namespace> get secrets <minio-deployment> -o jsonpath="{.data.secretkey}" | base64 -d)
```

## 8. Typical issues with microk8s
When using microk8s directly on a non-Ubuntu/Debian distro, you might encounter multiple errors:
* "error: cannot install 'microk8s': classic confinement requires snaps under /snap or symlink from /snap to /var/lib/snapd/snap" which is due to the missing [confinement environment](https://docs.snapcraft.io/snap-confinement/6233) on non Ubuntu/Debian distros, 
and can be solved with `sudo ln -s /var/lib/snapd/snap /snap`.
* "error while loading shared libraries: libselinux.so.1: cannot open shared object file: No such file or directory" which is due to the missing libselinux libraries and can be easily solved installing them. For instance on archlinux the libselinux is available 
on AUR.

