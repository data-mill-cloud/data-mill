# Traefik 
[Traefik](https://docs.traefik.io/) is an HTTP reverse proxy, load balancer and Ingress Controller for Kubernetes.

![](https://docs.traefik.io/img/architecture.png)

# 1. Installation
This component installs Traefik using the community provided [Helm chart](https://github.com/helm/charts/tree/master/stable/traefik).

# 2. Writing an Ingress
Traefik can be used as Ingress controller to expose cluster services (typically HTTP and HTTPS) to the outside.

As defined in the [official Traefik documentation](https://docs.traefik.io/user-guide/kubernetes/),
 a basic Ingress can be defined for a Service as:
```
apiVersion: v1
kind: Service
metadata:
  name: traefik-web-ui
  namespace: kube-system
spec:
  selector:
    k8s-app: traefik-ingress-lb
  ports:
  - name: web
    port: 80
    targetPort: 8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-web-ui
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: traefik-ui.minikube
    http:
      paths:
      - path: /
        backend:
          serviceName: traefik-web-ui
          servicePort: 80
```
The example exposes the traefik web UI adding a route for `/`.
For it is possible to run multiple ingress controllers on the same cluster, the annotation `kubernetes.io/ingress.class: traefik` specifies which one to use.

Also, if you restrict access to the resource from a specific host, i.e. traefik-ui.minikube, you have to make sure the host is reachable from DNS.
For a local cluster such as minikube and microk8s one can do:
* *minikube* - `echo "$(minikube ip) traefik-ui.minikube" | sudo tee -a /etc/hosts`
* *microk8s* - `microk8s.kubectl config view | grep server: | awk 'print $2' | sudo tee -a /etc/hosts`
* *any* - `kubectl config view | grep server: | awk 'print $2' | sudo tee -a /etc/hosts`
