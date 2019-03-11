# Kafka

Apache Kafka is a distributed messaging platform designed to build real-time data pipelines and streaming applications.  
This component installs [Strimzi](https://strimzi.io/), which is a [Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator/tree/master/helm-charts/strimzi-kafka-operator) provided by RedHat for Kubernetes and Openshift.
The official documentation is available [here](https://strimzi.io/docs/0.5.0/).
Along with the Kafka operator, this component also deploys a Kafka cluster, as defined in the configurable example `kafka-persistent.yaml`. 
This deploys a pool of Zookeeper nodes, multiple broker nodes and an entity operator for the cluster. The deployed Kafka broker and Zookeeper nodes use a persistentvolumeclaim (PVC) to acquire a persistentVolume (PV) and store their data. A specific storage 
class can be used for this purpose.
Further examples to create custom resources (CRD) for the Strimzi Kafka operator are available [here](https://github.com/strimzi/strimzi-kafka-operator/tree/master/examples).

## Notes
* The component does not install a schema registry. An Helm chart for the schema registry can be found [here](https://github.com/helm/charts/tree/master/incubator/schema-registry).
* The Strimzi operator can also manage [Kafka-connect clusters](). However, the basic connector image only has a simple file connector. To add further plugins a custom docker image can be built. Please follow the official guide 
[here](https://strimzi.io/docs/master/#creating-new-image-from-base-str).
