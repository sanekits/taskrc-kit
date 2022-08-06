#!/bin/bash

# Running taskrc-kit-version.sh is the correct way to
# get the home path for taskrc-kit and its tools.
TaskrckitVersion=0.8.1

set -e

Script=$(readlink -f "$0")
Scriptdir=$(dirname -- "$Script")


if [ -z "$sourceMe" ]; then
    printf "%s\t%s" ${Scriptdir}/taskrc_loader ${TaskrckitVersion}
fi