# Apache Flink

## 1. Distributed Runtime Environment

This components uses the official Flink docker image to spawn a Flink Session cluster: a JobManager (i.e. a cluster master), along with a REST interface and a UI, as well as a pool of TaskManager pods (i.e. workers).
An image of the Flink architecture is provided below, while a full introduction to is provided [here](https://ci.apache.org/projects/flink/flink-docs-release-1.7/concepts/runtime.html):

![Flink architecture](https://ci.apache.org/projects/flink/flink-docs-release-1.7/fig/processes.svg)

Flink can be deployed either as session cluster, i.e. as a long-running Kubernetes Deployment, or as a Job cluster, i.e. as a cluster dedicated to a single job and that terminates with the job.
The session cluster uses the `flink:latest` image, and thus a job has to be explicitly submitted. 

On the contrary, the job cluster packs the Flink Jar in a Flink docker runtime, i.e. the job is already included and directly launched.
A job, i.e. a flink dataflow graph, is packaged in a self-contained Docker image which can be launched to create a dedicated job cluster.

See [Sect. 2](#2-deploying-a-session-cluster-using-the-provided-helm-chart) on how to start a Session Cluster, [Sect. 3](#3-packaging-flink-code) on how to package your code, and [Sect. 4](#4-deploying-a-flink-job-cluster) on how to deploy a Job Cluster.

## 2. Deploying a Session Cluster using the provided Helm chart  
The provided Helm Chart takes care of creating the Job manager, as well as the service and the pool of task managers.
Specifically, we follow the [official Flink guide for K8s](https://ci.apache.org/projects/flink/flink-docs-stable/ops/deployment/kubernetes.html#session-cluster-resource-definitions). For this setup, please set `flink.type=session` in the component `config.yaml` file.

## 3. Packaging Flink code  
The packaging of a Flink Job is done on the following steps:  
1. Package the Flink code in a Jar  
  * run `mvn clean package` inside the project folder to clean and recreate the target Jar
2. Build the docker image with the Flink runtime and topology using the build.sh script  
The [build.sh](https://github.com/apache/flink/blob/master/flink-container/docker/build.sh) does simply run a `docker build -t <IMAGE_NAME>`, with the IMAGE_NAME that is something like `flink-job:latest`, on [this Dockerfile](https://github.com/apache/flink/blob/master/flink-container/docker/Dockerfile). 
The script combines the specified job jar with a Flink distribution as: i) an official release, ii) an archive, iii) a specific local target distribution:  
  * `build.sh --from-local-dist --job-jar <PATH_TO_JOB_JAR> --image-name <IMAGE_NAME>`
  * `build.sh --from-archive <PATH_TO_ARCHIVE> --job-jar <PATH_TO_JOB_JAR> --image-name <IMAGE_NAME>`
  * `build.sh --from-release --flink-version 1.6.0 --hadoop-version 2.8 --scala-version 2.11 --image-name <IMAGE_NAME>`
3. Push the built docker image to the target docker repo we commonly use for our artifacts  
  * `docker login`
  * `commit_tag=$(docker images <IMAGE_NAME> | awk 'FNR > 1{ print $3 }')` to retrieve the commit tag for our flink job
  * `docker tag $commit_tag <IMAGE_NAME>` to tag the image (in case we used a different tag:version combination for the build)
  * `docker push <IMAGE_NAME>` to push to the target docker repo

After those 3 steps are followed, we should have the Flink job available in our docker repository.
The [image](https://github.com/apache/flink/blob/master/flink-container/docker/Dockerfile) used for the build inherits a standard Alpine JRE image, downloads the Flink Java source code and sets the entrypoint. The [entrypoint](https://github.com/apache/flink/blob/master/flink-container/docker/docker-entrypoint.sh) can be passed either "job-cluster" to start a jobmanager, or "task-manager" to start one of the workers.

## 4. Deploying a Flink Job Cluster  
### 4.1 Manual creation of the services
Once the code has been packaged and dockerized, a Job cluster can be created as a K8s Job:
  * create a flink job configuration file as in this [example](https://github.com/apache/flink/blob/master/flink-container/kubernetes/job-cluster-job.yaml.template). Mind that to resume from a checkpoint, the argument `--fromSavepoint <SAVEPOINT_PATH>` is to be set  
  * run `FLINK_IMAGE_NAME=<IMAGE_NAME> FLINK_JOB=<JOB_NAME> FLINK_JOB_PARALLELISM=<PARALLELISM> envsubst < flink-job-config.yaml | kubectl create -f -` to spawn the defined job  
  * the job is visible with `kubectl get job`
  * To access the web UI exposed by default at port 30081, a [service](https://github.com/apache/flink/blob/master/flink-container/kubernetes/job-cluster-service.yaml) can be defined for the job, or we otherwise just port-forward directly to the pod
  * Write a [deployment configuration](https://github.com/apache/flink/blob/master/flink-container/kubernetes/task-manager-deployment.yaml.template) to spawn multiple task manager pods (i.e. workers)

### 4.2 Use the Helm Chart to create the Job Cluster
For this setup, please set `flink.type=job` in the component `config.yaml` file.
