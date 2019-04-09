# Monitoring Stack

This component installs the [CoreOS Prometheus operator](https://github.com/coreos/prometheus-operator), along with an optional [Grafana](https://prometheus.io/docs/visualization/grafana/) dashboard to visualize collected metrics.

## Prometheus

Prometheus is an open-source platform to collect and store metrics from monitored components, which are accessed by scraping their exposed HTTP endpoints or by using specific exporters.
Prometheus consists of a number of components:
* a [server](https://github.com/prometheus/prometheus), which scrapes (pull) and stores time series;
* a bunch of [exporters](https://prometheus.io/docs/instrumenting/exporters/) from most common systems; which on K8s are typically deployed as sidecar container to monitor the main pod and expose Prometheus metrics;
* an [alert manager](https://github.com/prometheus/alertmanager) that takes care of handling alert messages;
* a [push gateway](https://github.com/prometheus/pushgateway) where short-lived jobs can export their metrics, i.e. they push the metrics to this endpoint instead of waiting Prometheus to pull them;
* a [query engine (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/) to expose the metrics and allow for basic processing capabilities, and an expression browser, available at `graph`, allowing to evaluate an expression and visualize it as 
either table or graph;

![Prometheus architecture](https://prometheus.io/assets/architecture.png)

### Data Model
Prometheus stores all data as time series, i.e. timestamped values grouped under a specific metric name.
In practice, a metric consists of multiple domains or labels, thus prometheus a metric is a multivariate time series. Metrics can be [exposed](https://prometheus.io/docs/instrumenting/exposition_formats/) using a simple text format.
A metric has format `<metric name>{<label name>=<label value>, ...} <value> <timestamp>`, where value is a float related to the metric (as well as `NaN`, `+Inf`, `-Inf`) and timestamp is an int64 (milliseconds since epoch).
Labels enrich the time series by providing context. The label name and value are UTF-8 strings. Naming convention is described [here](https://prometheus.io/docs/practices/naming/). As perceivable, Prometheus does not actually care of labels data types and flattens them into an untyped time series.
More complex [metrics](https://prometheus.io/docs/concepts/metric_types/), such as counters, gauges, histograms and summaries, can be defined on data. See [this](https://prometheus.io/docs/instrumenting/exposition_formats/#histograms-and-summaries) example.

By default metrics are stored in a local folder for a period of 15 days. On K8s this folder can be maintained on a persistent volume (PV) or a [StatefulSet](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) can be otherwise used to 
deploy the Prometheus server so that each of its pod are uniquely binded to specific volumes that are unambiguously re-used in case of failure and restart.

### Exporters

[Exporters](https://prometheus.io/docs/instrumenting/exporters/) are used in those cases in which a service does not directly expose Prometheus metrics.  
Typical examples are:
* the [JMX exporter](https://github.com/prometheus/jmx_exporter) for JVM-based applications;
* the [cAdvisor](https://prometheus.io/docs/guides/cadvisor/) to monitor docker containers;
* the [node exporter](https://github.com/prometheus/node_exporter) for the node phyisical metrics (e.g. CPU, RAM)
* the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) that accesses the k8s gateway and exports cluster metrics (e.g. deployment, pods) 

## The Prometheus K8s Operator

As mentioned, this component installs the Prometheus K8s operator, along with the alert manager and grafana.
As such, the component eases not only the setup but also the maintanance of Prometheus and its monitored targets.
The operator uses a [custom controller](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-controllers) to implement basic expert rules for cluster management, such as cluster setup (prometheus servers, alert manager, 
grafana, kube-state-metrics and host node_exporter) and cluster scale up/down.  
Moreover, the operator uses Custom Resource Definitions (CRDs) and ConfigMaps to make Prometheus configuration accessible as any other K8s resource, specifically:
* `Prometheus` defining the prometheus server deployment;
* `Alertmanager` defining the alert manager deployment;
* `ServiceMonitor` defining the actual targets to be monitored by the server, by automatically generating scraping rules for those;
* `PrometheusRule` defining prometheus rules, i.e. i) [recording rules]((https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)) to perform certain calculations and produce new time series and ii) [alerting 
rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) to define event-condition-action rules and send alerts on external services;

A more complete guide to setting up rules on the Prometheus operator is provided [here](https://sysdig.com/blog/kubernetes-monitoring-with-prometheus-alertmanager-grafana-pushgateway-part-2/) and 
[here](https://sysdig.com/blog/kubernetes-monitoring-prometheus-operator-part3/).

