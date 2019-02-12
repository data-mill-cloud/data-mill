# Ambassador
Ambassador is an open source API gateway for Kubernetes, built on the Envoy proxy.  

## 1. Installation
This component uses Helm to install Ambassador.
Ambassador is exposed by default as LoadBalancer service. While this resource can be requested on a cloud-provided cluster, this is generally not available on bare metal clusters (since LoadBalancers are lower-level network resources), such as minikube and 
microk8s. For those, Ambassador can be set to use NodePort. Alternatively, the component [metallb](https://github.com/data-mill-cloud/data-mill/tree/master/infrastructure/components/metallb) can be installed to allocate a local IP and a load balancer as requested 
by Ambassador.

## 2. Getting started
A getting started guide to Ambassador is provided [here](https://www.getambassador.io/user-guide/getting-started/).
As mentioned in the example, every service that wants to be accessible through Ambassador from outside the cluster needs to define an annotation of kind:
```
apiVersion: v1
kind: Service
metadata:
  name: qotm
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind:  Mapping
      name:  qotm_mapping
      prefix: /qotm/
      service: qotm
spec:
  selector:
    app: qotm
  ports:
  - port: 80
    name: http-qotm
    targetPort: http-api
```
Ambassador continuously monitors the cluster for those annotations and is able to add or change routing rules for annotated services.  

## 3. Ingress controllers Vs. Ambassador
Distributing routing rules on the individual components as opposed to a centralised configuration, is in fact similar to the concept of [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), where a central [Ingress 
controller](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers) seeks for Ingress Resources, i.e. a Kubernetes resource that wraps a Service to specify its routing information.
Although still in Beta, Ingress is a core Kubernetes concept, and as such it can benefit of kubectl and all other typical K8s resource management tools.
In addition, certain cloud providers such as GCE/GKE deploy an Ingress controller on the master, while on on-premise clusters a controller should be explicitly deployed.  

There exist multiple Ingress controllers, such as based on [Istio](https://istio.io/docs/tasks/traffic-management/ingress/), [nginx](https://www.nginx.com/products/nginx/kubernetes-ingress-controller) and [Traefik](https://docs.traefik.io/user-guide/kubernetes/).
As mentioned in the Ingress documentation, we can easily add an Ingress resource for a Service:
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /testpath
        backend:
          serviceName: test
          servicePort: 80
```

A cluster can simultaneously run multiple ingress controllers. In this case, when creating an ingress the target ingress controller has to be specified using the specific `ingress.class`, or a default one may be used otherwise.
Ideally, all Ingress controllers should respect the basic ingress resource definition, though they may operate slightly differently for certain functionalities.  

If you are looking for an Ingress controller, mind that Ambassador provides a superset of a typical controller's functionalities.
[This blog post](https://blog.getambassador.io/kubernetes-ingress-nodeport-load-balancers-and-ingress-controllers-6e29f1c44f2d) explains differences, while [this section](https://www.getambassador.io/concepts/developers/#ingress-resources) of Ambassador 
documentation explains why Ambassador does not support Ingress resources.

Among others, Ambassador is [used in the Kubeflow project](https://kubernetes.io/blog/2018/06/07/dynamic-ingress-in-kubernetes/) to manage routing with Kubernetes annotations. This way, Kubeflow redirects all external traffic to Ambassador that does forward to the 
individual service for each request.
