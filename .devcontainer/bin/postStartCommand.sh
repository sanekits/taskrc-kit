#!/bin/bash

die() {
    echo "ERROR: $*" >&2
    exit 1
}

set -x
command ln -sf /host_home/.gitconfig ~/ || die 101
command ln -sf /host_home/my-home ~/ || die 102
ln -sf /host_home/bin ~/
mkdir -p ~/projects
ln -sf /host_home/bin/bashrc-common ~/.bashrc
ln -sf /host_home/bin/inputrc ~/.inputrc
