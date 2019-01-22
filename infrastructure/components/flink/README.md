# Apache Flink

## 1. Distributed Runtime Environment

This components uses the official Flink docker image to spawn a Flink Session cluster: a JobManager (i.e. a cluster master), along with a REST interface and a UI, as well as a pool of TaskManager pods (i.e. workers).
An image of the Flink architecture is provided below, while a full introduction to is provided [here](https://ci.apache.org/projects/flink/flink-docs-release-1.7/concepts/runtime.html):

![Flink architecture](https://ci.apache.org/projects/flink/flink-docs-release-1.7/fig/processes.svg)

As visible, a job can be submitted to the session cluster once this has been created.
A job, i.e. a flink dataflow graph, is packaged in a self-contained Docker image which can be launched to create a dedicated job cluster.
We refer to [this example](https://github.com/apache/flink/blob/release-1.7/flink-container/kubernetes/README.md#deploy-flink-job-cluster) on how to run a Flink job on the set up Flink component.
