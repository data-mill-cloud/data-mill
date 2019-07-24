#!/bin/sh

get_latest_github_release() {
	# taken from https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"([^"]+)".*/\1/'
}

get_latest_github_tag() {
	# for those repos that tag but do not use github releases
	curl --silent "https://api.github.com/repos/${1}/tags" |
	python -c "import sys; import json; raw=json.loads(sys.stdin.read()); print(raw[0]['name']) if len(raw)>0 else ''"
}

# e.g.
#echo $(get_latest_github_release data-mill-cloud/data-mill)
#echo $(get_latest_github_tag "NVIDIA/k8s-device-plugin")