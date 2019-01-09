#!/bin/bash

helm package $1
mv $1*.tgz ../../docs/helm-charts/
