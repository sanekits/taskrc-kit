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

canonpath() {
    builtin type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    builtin type -t readlink &>/dev/null && {
        command readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( builtin cd -L -- "$(command dirname -- $0)"; builtin echo "$(command pwd -P)/$(command basename -- $0)" )
}

mydir=$(canonpath $0)
[[ -f $mydir/bin/taskrc-kit.bashrc ]] || errExit "Can't find dir for $0"

function main {
    local topDir=${1:-$HOME}
    sourceMe=1 source $mydir/taskrc-kit.bashrc
    (
        cd ${topDir} || return $(errExit cant find topDir $topDir)
        find -L -type f -name taskrc -o -name taskrc.md | tee /dev/pts/3 | ( while read; do echo "$REPLY" ; register_taskrc $(dirname $REPLY); done ; )
    )
}

[[ -z $sourceMe ]] && main $@
