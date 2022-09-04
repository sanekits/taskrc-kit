#!/bin/bash
# taskrc_register_all.sh
#
#  Find all taskrc files and register them in ~/.taskrc_reg
#
#

function errExit {
    echo "ERROR: $@" >&2
    exit 1
}

mydir=$(dirname $0)
[[ -f $mydir/taskrc-kit.bashrc ]] || errExit "Can't find dir for $0"

function main {
    local topDir=${1:-$HOME}
    sourceMe=1 source $mydir/taskrc-kit.bashrc
    (
        cd ${topDir} || return $(errExit cant find topDir $topDir)
        find -L -type f -name taskrc -o -name taskrc.md | tee /dev/pts/3 | ( while read; do echo "$REPLY" ; register_taskrc $(dirname $REPLY); done ; )
    )
}

[[ -z $sourceMe ]] && main $@
