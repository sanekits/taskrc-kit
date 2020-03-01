#!/bin/bash
# taskrc.sh: scriptable wrapper for the taskrc() function in taskrc_loader

mydir="$(readlink -f $(dirname $0)/)"

source "${mydir}/taskrc_loader"

[[ -z $1 ]] && { echo "ERROR: at least one argument required" >&2; exit 1 ; }
taskrc_v2 $@
