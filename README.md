```
--------

8888888b.           888                    888b     d888 d8b 888 888
888  "Y88b          888                    8888b   d8888 Y8P 888 888
888    888          888                    88888b.d88888     888 888
888    888  8888b.  888888  8888b.         888Y88888P888 888 888 888
888    888     "88b 888        "88b        888 Y888P 888 888 888 888
888    888 .d888888 888    .d888888 888888 888  Y8P  888 888 888 888
888  .d88P 888  888 Y88b.  888  888        888   "   888 888 888 888
8888888P"  "Y888888  "Y888 "Y888888        888       888 888 888 888

--------
```

# Data-Mill: A K8s-based lambda architecture for analytics

![Architecture sketch](https://raw.githubusercontent.com/data-mill-cloud/data-mill/master/docs/img/architecture.png | width=800)


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
