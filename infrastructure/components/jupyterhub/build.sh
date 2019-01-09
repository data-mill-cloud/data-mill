# building the DS environments
repo=datamillcloud
version=0.1
env_path=ds_environments/*

docker login
# --username=$repo

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

for e in $env_path; do
  n=$(basename "$e")
  t=$repo/$n
  if [[ "$(docker images -q $t:$version 2> /dev/null)" == "" ]]; then
    echo "Building DS Environment $n ($t) at $e"
    echo "docker build -t $t:$version -f $e/Dockerfile ."
    #docker build -t $t:$version -f $e/Dockerfile .
  else
    echo "Image $t:$version already exists in the local repository"
  fi

  commit_tag=$(docker images $t:$version | awk 'FNR > 1{ print $3 }')
  if [ -z $commit_tag ]; then
    echo "-> Build failed for $t:$version! skipping."
  # check if image already exists on remote repo
  elif [ $(check_tag_in_dh_repo $t $version) == "true" ]; then
    echo "$t:$version already exists on DockerHub! Skipping!"
  else
    echo "-> docker tag $commit_tag $t:$version"
    #docker tag $commit_tag $t:$version
    echo "-> docker push $t"
    #docker push $t
    echo "-> docker tag $commit_tag $t:latest"
    #docker tag $commit_tag $t:latest
    echo "-> docker push $t"
    #docker push $t
  fi

  echo "--"
done
