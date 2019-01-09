#!/bin/bash

t=datamillcloud/mlflow
version=0.1

docker login

docker build --build-arg ml_folder=/mnt/mlflow_data -t $t:$version -f Dockerfile .
commit_tag=$(docker images $t:$version | awk 'FNR > 1{ print $3 }')
echo "Commit tag: $commit_tag"

echo "-> docker tag $commit_tag $t:$version"
docker tag $commit_tag $t:$version
echo "-> docker push $t"
docker push $t

echo "-> docker tag $commit_tag $t:latest"
docker tag $commit_tag $t:latest
echo "-> docker push $t"
docker push $t
