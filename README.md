<img src="https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/logos/logo_data_mill_2.png" width="200">

---
# Data-Mill: A K8s-based lambda architecture for analytics

![Architecture sketch](https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/architecture.png)


Providing:  
  1. K8s setup  
    * [Local](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/k8s) (i.e. Minikube)  
    * [Remote](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/k8s/kops) (e.g. VM, K8s Cluster)  
  2. Setup of [common components](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/components)  
    * Ingestion (e.g. kafka, RabbitMQ)  
    * Persistent storage (e.g. s3)  
    * Data Versioning (e.g. Pachyderm)  
    * Processing (e.g. dask, spark)  
    * Exploration Environment (e.g. JupyterHub)  
    * BI Dashboarding (e.g. superset)  
    * ML model versioning and benchmarking, as well as project management (e.g. mlflow)  
    * ML model serving (e.g. Seldon-core)  
    * Monitoring (e.g. prometheus, Grafana)  
  3. Data Science Environments  
    * [Scientific Python Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/python_env/Dockerfile)  
    * [PySpark Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/pyspark_env/Dockerfile)  
    * [Keras/Tensorflow Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/pydl_env/Dockerfile)  
    * [Keras/Tensorflow GPU Environment](https://github.com/data-mill-cloud/data-mill/blob/master/infrastructure/components/jupyterhub/ds_environments/pydl_gpu_env/Dockerfile)  
  4. Example Applications  
    * Access to services - [notebooks](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/data)
    * Batch processing  
    * Stream processing  
