#! /usr/bin/env bash

github_url="https://github.com/OpenKinect/libfreenect2"
dest="$HOME/src/libfreenect2"

# by default, set the previous commit to -1, which will trigger a 'make'
prev="-1"

if [[ -d "$dest" ]]
then
    # shellcheck disable=SC2164
    cd "$dest"
    current_url=$(git config --get remote.origin.url) # get the remote
    current_url_corrected="$(_git_https_or_ssh "$current_url")"
    github_url_corrected="$(_git_https_or_ssh "$github_url")"

    # if the repo is pointing to the wrong remote, correct it
    if [ "$current_url_corrected" != "$github_url_corrected" ]
    then
        tue-install-debug "The repo is pointing to the wrong remote, will be changed to $github_url_corrected"
        git remote set-url origin "$github_url_corrected"
    fi

    # Git is set-up correctly, so record the previous commit
    prev=$(git -C "$dest" rev-list HEAD -n 1)
fi

# tue-install-git will decide if clone or pull is needed
tue-install-git $github_url "$dest"

# make if needed
build_folder="$dest"/build

# shellcheck disable=SC2164
if [[ "$prev" != "$(git -C "$dest" rev-list HEAD -n 1)" ]] || [[ ! -d "$build_folder" ]]
then
    tue-install-debug "Making libfreenect2"
    if [[ ! -d "$build_folder" ]]
    then
        mkdir "$build_folder"
    fi
    cd "$build_folder"
    cmake .. -DCMAKE_INSTALL_PREFIX="$HOME"/freenect2
    make
    sudo make install
else
    tue-install-debug "libfreenect2 not updated, so no need to make again"
fi

if [[ ! -L /etc/udev/rules.d/90-kinect2.rules ]]
then
    tue-install-debug "Coping udev rules"
    sudo ln -s "$dest"/platform/linux/udev/90-kinect2.rules /etc/udev/rules.d/
fi
