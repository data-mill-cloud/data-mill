#!/usr/bin/env bash

echo "Updating helm repo index"
helm repo index helm-charts --url https://data-mill-cloud.github.io/data-mill/helm-charts/

