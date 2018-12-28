#!/bin/sh

get_value() {
	cat $1 | grep "name: " | awk -F": " '{ print $2 }'
}
