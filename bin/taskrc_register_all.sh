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

function main {
    local topDir=${1:-$HOME}
    sourceMe=1 source ~/bin/taskrc_loader
    (
        cd ${topDir} || return $(errExit cant find topDir $topDir)
        find -type f -name taskrc | ( while read; do echo "$REPLY" ; register_taskrc $REPLY; done ; )

    )
}

[[ -z $sourceMe ]] && main $@
