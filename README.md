# Data-Mill: A K8s-based lambda architecture for analytics

![Architecture sketch](https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/architecture.png)


Providing:  
  1. K8s setup  
    * Local (i.e. Minikube)  
    * Remote (e.g. VM, K8s Cluster)  
  2. Setup of common components  
    * Ingestion (e.g. kafka)  
    * Persistent storage (e.g. s3)  
    * Processing (e.g. dask, spark)  
    * Exploration Environment (e.g. JupyterHub)  
    * BI Dashboarding (e.g. superset)  
    * ML model benchmarking and project management (e.g. mlflow)  
    * ML model serving (e.g. Seldon-core)  
    * Monitoring (e.g. prometheus, Grafana)  
  3. Example Applications  
    * Batch processing  
    * Stream processing  
