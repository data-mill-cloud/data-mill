# Apache NiFi

[Apache NiFi](https://nifi.apache.org/) is a tool built to manage data flow charts to distribute computations on data. The project licensed under the Apache 2.0.
NiFi addresses most common issues in the ingestion stage, i.e., that of moving and wrangling data across different data stores and formats, on both a real-time and batch fashion.
As such, it overlaps with workflow management systems, such as Oozie, Argo and Airflow, as well as with batch and stream processing tools such as Hadoop Map Reduce and Storm/Flink.

Nifi can offer an all-in-one solution for operating data, especially for companies that want to quickly achieve a MVP without having to implement costly ETL pipelines.

This component installs NiFi as [K8s operator](https://github.com/b23llc/nifi-fn-operator) (see blog [post](https://medium.com/@b23llc/announcing-serverless-data-flows-using-b23-kubernetes-operator-for-nifi-fn-c4b24a784cc6)).
The component provides an optional NiFi registry, that can be used as web interface to design and test new flows. 
