#!/bin/sh

# 1: namespace
# 2: service name
# 3: service port
# 4: route path
# 5: host
# 6: ingress.class
get_ingress_def(){

# add preamble
ingress_def=\
"apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ${2}
  namespace: ${1}
"

if [ ! -z "${6}" ]; then
ingress_def=${ingress_def}\
"  annotations:
    kubernetes.io/ingress.class: ${6}
"
fi

# add spec section
ingress_def=${ingress_def}\
"spec:
  rules:
  - http:
      paths:
      - path: ${4}
        backend:
          serviceName: ${2}
          servicePort: ${3}
"

if [ ! -z "${5}" ]; then
ingress_def=${ingress_def}\
"    host: ${5}
"
fi

echo "${ingress_def}"
}


create_ingress(){
	echo "$(get_ingress_def $@)" | kubectl create --namespace=${1} -f -
}

# example usages:
#echo "$(get_ingress_def '1' '2' '3' '4' '5' '6')"
#"$(create_ingress '1' '2' '3' '4' '5' '6')"
