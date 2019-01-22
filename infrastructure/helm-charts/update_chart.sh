#!/bin/bash

helm package $1
echo "moving package for $1 at docs/helm-charts/"
mv $1*.tgz ../../docs/helm-charts/
