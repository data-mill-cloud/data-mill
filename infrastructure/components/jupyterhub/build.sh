# building the DS environments
repo=datamillcloud
version=0.1
env_path=ds_environments/*

docker login --username=$repo

for e in $env_path; do
  n=$(basename "$e")
  t=$repo/$n
  echo "Building DS Environment $n ($t) at $e"
  echo "docker build -t $t:$version -f $e/Dockerfile ."
  docker build -t $t:$version -f $e/Dockerfile .
  commit_tag=$(docker images $t:$version | awk 'FNR > 1{ print $3 }')
  if [ -z $commit_tag ]; then
    echo "-> Build failed for $t:$version! skipping."
  else
    echo "-> docker tag $commit_tag $t:$version"
    docker tag $commit_tag $t:$version
    echo "-> docker push $t"
    docker push $t
    echo "-> docker tag $commit_tag $t:latest"
    docker tag $commit_tag $t:latest
    echo "-> docker push $t"
    docker push $t
  fi
done
