#!/bin/bash

kafka_version=2.1.1
tag="datamillcloud/appdebugger"
version="0.1"

get_tags_from_dh_repo(){
  curl -s "https://hub.docker.com/v2/repositories/$1/tags/" | \
  python3 -c "import sys, json; jres=json.load(sys.stdin); print('' if ('detail' in jres and jres['detail']) or (jres['count'] <= 0) else ' '.join([r['name'] for r in jres['results']]))"
}

check_tag_in_dh_repo(){
  tags=( $(get_tags_from_dh_repo $1) )
  for e in "${tags[@]}"; do
    if [[ $e == $2 ]]; then
      echo "true"
      break
    fi
  done
  # returns True if found or "" otherwise
}

docker login
docker build --build-arg v_kafka=${kafka_version} -t ${tag}:${version} -f Dockerfile .
commit_tag=$(docker images "${tag}:${version}" | awk 'FNR > 1{ print $3 }')

if [ -z $commit_tag ]; then
  echo "-> Build failed for ${tag}:${version}! skipping."
elif [[ $(check_tag_in_dh_repo $tag $version) == "true" ]]; then
  echo "${tag}:${version} already exists on DockerHub! Skipping!"
else
  echo "-> docker tag $commit_tag ${tag}:${version}"
  docker tag $commit_tag "${tag}:${version}"
  echo "-> docker push ${tag}"
  docker push ${tag}
fi

# tests
# run as docker container
#docker run -it ${tag}:${version}
# run as cluster pod
#kubectl run -i -t kafka-client --restart='Never' --image=${tag}:${version} --replicas=1
