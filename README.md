<img src="https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/logos/logo_data_mill_2.png" width="200">

---
# Data-Mill: A K8s-based lambda architecture for analytics

Triggered by the Data Science hype, many companies started working on the topic but only few are really successfull. The main barrier is the gap between the expectations of the stakeholders and the actual value delivered by models, as well as the lack of 
information over incoming data, in terms of both data quality and the processes producing them.  In addition, projects require a very interdisciplinar team, including system administrators, engineers, scientists, as well as domain experts. Consequently, a 
significant investment and a clear strategy are necessary to succeed.

Moreover, typical lambda architectures (i.e. one that combines a streaming layer to a batch one) bring in significant complexity and potential technical gaps. Whilst continuous-integration and deployment (CICD) can automate and speed up to a great extent (using 
unit and integration tests, as well as frequent releases) the software development cycle, generally data scientists tend to work in a different workflow, and are often operating aside the rest of the team with consequent information gaps and unexpected behaviors 
upon changes on the data they use and the models they produced.

In this setup, waste of resources is the norm.  

The goal is therefore to enforce [DataOps practices](http://dataopsmanifesto.org/) and provide a complete-cloud agnostic architecture to develop data analytics applications:  
  1. Data ingestion  
    * logs - Confluent Kafka ecosystem  
    * sensor data - AMQP and MQTT protocols (e.g. RabbitMQ)  
  2. Data storage and versioning  
    * local S3 datalake (e.g. minio)  
    * data versioning (i.e. pachyderm)  
  3. Data processing  
    * batch processing (e.g. Dask, Spark)  
    * stream processing (e.g. KSQL and Kafka streams, Spark Streaming, Flink)  
  4. Monitoring of distributed services  
    * metrics - timeseries database and dashboarding tool (e.g. prometheus and graphana)  
    * logs - Elastic stack  
  5. Data Exploration  
    * spawnable development environments (e.g. Jupyterhub)  
  6. Experiment tracking  
    * model training, benchmarking and versioning  
    * versioning of development environment  
  7. Model serving  
    * collection of model performance and user interaction (e.g. AB testing)  

Data-Mill already provides:  
  1. K8s setup  
    * [Local](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/k8s) (i.e. Minikube, MicroK8s)  
    * [Remote (experimental)](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/k8s/kops) (i.e. AWS, GKE)  
  2. Overlay network  
  3. Setup of [common components](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/components)  
    * Ingestion (e.g. kafka, RabbitMQ)  
    * Persistent storage (e.g. s3, ArangoDB, InfluxDB, Cassandra)  
    * Data Versioning (e.g. Pachyderm)  
    * Processing (e.g. dask, spark, flink)  
    * Exploration Environment (e.g. JupyterHub)  
    * Text Analytics (e.g. elasticsearch)  
    * BI Dashboarding (e.g. superset)  
    * ML model versioning and benchmarking, as well as project management (e.g. mlflow)  
    * ML model serving (e.g. Seldon-core)  
    * Monitoring (e.g. prometheus, Grafana)  
  4. Data Science Environments  
    * [Scientific Python Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/python_env/Dockerfile)  
    * [PySpark Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/pyspark_env/Dockerfile)  
    * [Keras/Tensorflow Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/pydl_env/Dockerfile)  
    * [Keras/Tensorflow GPU Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/pydl_gpu_env/Dockerfile)  
  5. Example Applications  
    * Access to services - [notebooks](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/data)  
    * Batch processing  
    * Stream processing  

---
<div style="text-align:center"><img src="https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/logos/logo_data_mill_2.png" width="200"></div>

The Data Mill logo reflects the purpose of a team embarking on a data science project.
The Mill is the place where farmers bring their wheat to produce flour and finally bread. As such, it is the most important place in a village to process raw material and obtain added value, Food.
The inner Star is a 8-point one, this is generally used to represent the Polar Star, historically used for navigation.

---

## Installation
1. Select a target folder e.g. user home
```
export DATA_MILL_HOME=$HOME
```
2. Download and run installation script to the target directory  
```
wget https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/install.sh --directory-prefix=$DATA_MILL_HOME
cd $DATA_MILL_HOME
sudo chmod +x install.sh
./install.sh
rm install.sh
```
This downloads the latest version of data-mill at $DATA_MILL_HOME and copies the run.sh to the /usr/local/bin to make it callable from anywhere.  
