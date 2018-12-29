#!/usr/bin/env bash

get_os_type() {
	case "$(uname -s)" in
		Linux*|CYGWIN*|MINGW*) echo "Linux";;
		Darwin*) echo "Mac";;
		*) echo "?"
	esac
}
