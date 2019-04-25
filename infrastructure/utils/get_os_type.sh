#!/usr/bin/env bash

get_os_type() {
	case "$(uname -s)" in
		Linux*|CYGWIN*|MINGW*) echo "Linux";;
		Darwin*) echo "Mac";;
		*) echo "?"
	esac
}

get_pacman(){
	# one of these commands should always be available to install packages
	pacmans=( yum apt-get pacman )

	for i in "${pacmans[@]}"
	do
		command -v $i > /dev/null 2>&1 && {
			echo $i
			break
		}
	done
}
