#!/bin/bash
# taskrc.sh: scriptable wrapper for the taskrc() function in taskrc-kit.bashrc

mydir="$(readlink -f $(dirname $0)/)"

source "${mydir}/bin/taskrc-kit.bashrc"

[[ -z $1 ]] && { echo "ERROR: at least one argument required" >&2; exit 1 ; }
taskrc_v5 $@
