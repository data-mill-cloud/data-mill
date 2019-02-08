# Metallb
There exists multiple ways of exposing a service in a Kubernetes cluster: i) ClusterIP to expose it only across the cluster, ii) NodePort to explicitly set a port-forwarding rule on each cluster node to the service port, iii) LoadBalancer to use a static IP 
address and spin up a network load balancer for the service, as well as iv) adding an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) rule for an existing service (e.g. defined as ClusterIP service) so that multiple services can be 
exposed by a single ingress. Using an ingress allows exposing one individual load balancer, which is both clean (since it centralizes the burden of routing requests to one controller) and useful to limit costs, since each exposed IP implies costs, especially when 
using a cloud-provided infrastructure.

[This article](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0) provides a thorough comparison of what just introduced.  

This component installs [metallb](https://metallb.universe.tf), a [network load balancer](https://cloud.google.com/load-balancing/docs/network/) for bare metal Kubernetes clusters, i.e. for on-premise and local clusters where allocating IP addresses depends on 
local routing rules, as opposed to cloud-provided Kubernetes clusters where this resource is billed separately. Metallb adds an implementation for network load balancers, which is not provided by Kubernetes itself, and without which causes any LoadBalancer 
resource to remain in the "Pending" state for indefinite time (until explicitly created).

Specifically, metallb [takes care of requesting IP addresses](https://metallb.universe.tf/concepts/) for LoadBalancer service types, by using standard protocols such as ARP, NDP and BGP. 
A configuration guide is provided [here](https://metallb.universe.tf/configuration/). For clusters placed in one individual network (i.e. one DHCP server), using layer2 addressing is enough and is simply defined by specifying the IP address range for which metallb 
has to request IPs in. Please check the `metallb_config.yaml` for an example of this kind.
