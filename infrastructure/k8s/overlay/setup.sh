#!/usr/bin/env bash

# installing flannel
# https://github.com/coreos/flannel#deploying-flannel-manually
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
