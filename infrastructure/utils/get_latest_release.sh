#!/bin/sh

get_latest_github_release() {
	# taken from https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
	curl --silent "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'
}
