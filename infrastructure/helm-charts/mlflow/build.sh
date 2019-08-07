#!/bin/bash

t=datamillcloud/mlflow
version=0.1

docker login

# the build arguments are then passes as folder and artifact_folder ENV variables, which can be therefore overwritten with -e folder=whatever

docker build \
$( [ ! -z $http_proxy ] && echo "--build-arg proxy=$http_proxy" ) --build-arg ml_folder=/mnt/mlflow_data --build-arg ml_artifact_folder=/mnt/mlflow_data \
-t $t:$version -f Dockerfile .

#docker build --build-arg ml_folder=/mnt/mlflow_data --build-arg ml_artifact_folder=/mnt/mlflow_data -t $t:$version -f Dockerfile .

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
