#!/usr/bin/env bash

get_latest_github_release() {
        # taken from https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
        curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
        grep '"tag_name":' |                                              # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                      # Pluck JSON value
}

latest_version=$(get_latest_github_release "data-mill-cloud/data-mill")
echo "Latest data-mill release is "$latest_version

wget "https://github.com/data-mill-cloud/data-mill/archive/${latest_version}.tar.gz"
tar -zxvf "${latest_version}.tar.gz"

# the folder will be of kind - data-mill-0.2.0-alpha, i.e.
dm_folder="data-mill-"${latest_version:1}
dm_bin="data-mill-"${latest_version}

# make symlink to run
sudo ln -s $PWD/$dm_folder/infrastructure/run.sh /usr/local/bin/$dm_bin
#sudo chmod +x /usr/local/bin/$dm_bin

rm "${latest_version}.tar.gz"
