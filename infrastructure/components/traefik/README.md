# Traefik 
[Traefik](https://docs.traefik.io/) is an HTTP reverse proxy, load balancer and Ingress Controller for Kubernetes.

![](https://docs.traefik.io/img/architecture.png)

## 1. Installation
This component installs Traefik using the community provided [Helm chart](https://github.com/helm/charts/tree/master/stable/traefik).

## 2. Writing an Ingress
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

To setup https, a TLS certificate can be [easily](https://docs.traefik.io/user-guide/kubernetes/#add-a-tls-certificate-to-the-ingress) added to the ingress `spec:` as:
```
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
      - backend:
          serviceName: traefik-web-ui
          servicePort: 80
  tls:
   - secretName: traefik-ui-tls-cert
```
This way, the ingress refers a secret resource in the same namespace. The secret [must](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls) have two entries: `tls.key` and `tls.crt`.
A self-signed certificate can be created with openssl with:
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout <keyfilepath> -out <certfilepath> -subj "/k=v"
```
The subject is passed directly (without being prompted in an interactive session) with `-subj`, in the format `/type0=value0/type1=value1/type2=…,` where characters may be escaped by \ (backslash) and spaces are not skipped.
Specifically, fields in the certificate signing request (CSR) are `/C` country, `/ST` state, `/L` location, `/O` organization, `/OU` organizational unit or business department, `/CN` common name.
For the example:
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=traefik-ui.minikube"
```
This will create a `tls.crt` file for the certificate and a `tls.key` file for the key.
The secret resource can then be created for the certificate with: 
```
kubectl -n <namespace> create secret tls tls-secret --cert=path/to/tls.cert --key=path/to/tls.key
```
which for our example is:
```
kubectl -n kube-system create secret tls traefik-ui-tls-cert --key=tls.key --cert=tls.crt
```
If not already done, to enable https for traefik, it is necessary to configure the Helm's `values.yaml`.
Specifically, `ssl.enabled` should be set to true and `ssl.enforced` can be used to force the entire http traffic over https.

Alternatively, it is possible to specify a default certificate for all ingresses. This can be specified in the `values.yaml` file for this component at `ssl.defaultCert` and `ssl.defaultKey`.
Please see the [Chart's values](https://github.com/helm/charts/tree/master/stable/traefik) for more details.

Access to the service presented is however unprotected.  
In the simplest case, we can authenticate access in it using a username and password:
* `htpasswd -b -c authfile username password` creates a file `authfile` containing a pair `username:MD5-hashed-password` for the user `username` and the provided password;
* a [K8s secret resource](https://kubernetes.io/docs/concepts/configuration/secret/) is created with `kubectl create secret generic <secretname> --from-file <authfile> --namespace=<nsname>`, where the namespace is the same of the ingress (to make sure the ingress 
can access the secret resource);
* the ingress is defined with the annotations `traefik.ingress.kubernetes.io/auth-type: "basic"` and `traefik.ingress.kubernetes.io/auth-secret: "secretname"`;

Alternatively, this can be directly setup on the `values.yaml` file used to deploy traefik in Helm, by setting the section `ssl.auth.basic` for the created secret.

Please see the [official Traefik documentation](https://docs.traefik.io/user-guide/kubernetes/) for more advanced functionalities.
