# taskrc-kit.bashrc - shell init file for taskrc-kit sourced from ~/.bashrc
#  https://github.com/sanekits/taskrc-kit

taskrc-kit-semaphore() {
    [[ 1 -eq  1 ]]
}

[[ -f ${HOME}/.local/bin/taskrc-kit/taskrc-kit.bashrc ]] && {
    export TASKRC_KIT_HOME=${HOME}/.local/bin/taskrc-kit
}


#  This should be sourced in the shell, it has no value as an external command.  Run 'taskrc.sh' if you want
# a scriptable thing.
#
#   taskrc is a shell helper for directory-specific 'taskrc' files.  A taskrc file is "your
# favorite shell definitions that are focused on a particular project or task".
#
# Often the taskrc file is saved with a project source code base.
#
#

declare -x taskrc_dir  # Directory of the most-recently-loaded taskrc file
declare taskrc_load_time=0 # epoch timestamp (from ctimetkr) for MRL taskrc, used for dirty detection

lesstkr="less -FXRm"
which less &>/dev/null \
    || lesstkr=more


function errExit {
    echo "ERROR: $*" >&2
    exit 1
}

function ctimetkr {
    date +%s
}

# Stub debug-aid: paste and uncomment this line to invoke repltkr() where needed.
# while read -ep "Stub 102:" stub; do repltkr "$stub" || break; done
repltkr() {
    local eval_txt="$1"
    [[ -z $eval_txt ]] && { false; return; }
    eval "$eval_txt"
    res=$?
    echo "Command returned $res" >&2
}

function taskrc_is_dirty {
    local print=false
    local detail=false
    [[ $1 == "-pd" ]] && { print=true; detail=true; }
    [[ $1 == "-p" ]] && print=true
    local cur=$(ctimetkr $(taskrc_filename ${taskrc_dir}) )
    if (( $cur > $taskrc_load_time )); then
        if $print; then
            builtin echo -n "dirty"
            if $detail; then
                builtin echo -n ": $cur > $taskrc_load_time"
            fi
        fi
        builtin echo ""
        true
        return
    fi
    if $print; then
        builtin echo -n "unchanged"
        if $detail; then
            builtin echo -n ": $taskrc_load_time"
        fi
        builtin echo ""
    fi
    false
}


function register_taskrc {
    local dir="$1"
    for file in ${dir}/task{rc,rc.md}; do
        [[ -f "$file" ]] || continue
        local xpath=$(readlink -f "$file")
        local xhash=$(echo "$xpath" | md5sum | cut -d ' ' -f 1)
        [[ -L $HOME/.taskrc_reg/$xhash ]] \
            && continue
        mkdir -p $HOME/.taskrc_reg
        builtin cd $HOME/.taskrc_reg
        command ln -sf "${xpath}" ./${xhash}
        builtin cd - &>/dev/null
    done
}

function has_taskrc {
    local xdir=$1
    [[ -f $xdir/taskrc.md || -f $xdir/taskrc ]]
}

function taskrc_md_filter {
    local xo=false;
    while IFS= read -r line; do
        #echo "line=[$line]" >/dev/pts/1
        if $xo; then
            if [[ "$line" == "\`\`\`" ]]; then
                xo=false;
                continue
            fi
            builtin echo "$line"
        else
            if [[ "$line" == "\`\`\`bash" ]]; then
                xo=true;
                continue
            fi
        fi
    done < $1
}

function cat_taskrc {
    [[ -z "$1" || ! -d $1 ]] \
        && return
    [[ -f "$1/taskrc.md" ]] \
        && taskrc_md_filter "$1/taskrc.md"
    [[ -f "$1/taskrc" ]] \
        && cat "$1/taskrc"
}

function source_taskrc {
    # When "including" a taskrc within another, this is the
    # idiom:
    #   source_taskrc ../
    source <(cat_taskrc $1 )
}

function taskrc_filename {
    [[ -f $1/taskrc.md ]] && {
        builtin echo "$1/taskrc.md";
        return ;
    }
    builtin echo "$1/taskrc"
}

function taskrc_linecount {
    [[ -z "$1" || ! -d $1 ]] && {
        echo 0 ;
        return;
    }
    cat_taskrc $1 | command wc -l
}

function external_taskrc_call {
    # If user calls taskrc [args], and [args] are not recognized, then we
    # try to evaluate them as a possible call on a function defined in the current
    # taskrc script.
    #
    # This allows (for example) invocation of taskrc-defined functions from within an editor or python app, etc.
    # To avoid chaos, there are limitations that matter:
    #   1. $taskrc_dir must be defined in the calling environment, we don't attempt to find it
    #   2. $taskrc_dir/taskrc{.md} must exist
    #
    # To make this work, we create a subshell, source taskrc, verify that a function exists matching $1,
    # and then eval the full command in that subshell.
    [[ -z $taskrc_dir ]] \
        && return $(errExit "Unknown arguments(0): $@ [no taskrc_dir]" )

    has_taskrc $taskrc_dir \
        || return $(errExit "Unknown arguments(1): $@ [no taskrc]")

    (
        source_taskrc $taskrc_dir
        funcname=$1
        [[ -z $funcname ]] \
            && errExit "Unknown arguments(2): $@ [taskrc_dir=$taskrc_dir]"
        [[ $(builtin type -t $funcname) == function ]] \
            || errExit "$funcname is not a function"
        shift
        cmd="${funcname} $@"
        eval "$cmd"
    )
}

function taskrc_dir_find {
    local xd="$1"  # start search here
    local search_up=$2 # search parent?

    if [[ -r $(taskrc_filename $xd) ]]; then
        builtin echo ${xd}
        true
        return
    fi
    if $search_up; then
        if [[ $(dirname -- $xd) != '/' ]]; then
            taskrc_dir_find $(dirname -- $xd) $search_up  # Recurse
            return
        fi
    fi
    false
}

# The 'v5' in this function name refers only to the function, not the entire taskrc-kit:
function taskrc_v6 {

    local help=false       # -h, --help : print help for this function, then help for most recent taskrc
    local version=false    # -v, --version: print taskrc-kit version number
    local search_up=false  # -s, --search-up : find taskrc by searching parent dirs of .
    local refresh=false    # -r, --refresh : reload most recent taskrc (i.e. to pick up changes)
    local dump=false       # -d, --dump: print contents of most recent taskrc to stdout
    local info=false       # -i, --info: print information about most recent taskrc (path)
    local load=true        # Our default behavior is to find/load the taskrc
    local force=false      # -f, --force: do the thing anyway
    local new=false        # -n, --new: create a new taskrc here .
    local edit=false       # -e, --edit: edit current taskrc, then reload
    local catt=false       # -c, --cat:  cat to stdout the latest new-file template
    local inner_args=()    # Anything left over could be passed down
    while [[ ! -z $1 ]]; do
        case "$1" in
            -h|--help)
                help=true
                load=false
                ;;
            -v|--version)
                taskrc-kit-version.sh
                return
                ;;
            -s|--search-up)
                search_up=true
                ;;
            -i|--info)
                info=true
                ;;
            -r|--refresh)
                refresh=true
                ;;
            -rh|-hr)
                refresh=true
                help=true
                load=false
                ;;
            -f|--force)
                force=true
                ;;
            -d|--dump)
                dump=true
                ;;
            -i|--info)
                info=true
                ;;
            -e|--edit)
                edit=true
                ;;
            -n|--new)
                new=true
                ;;
            -c|--cat)
                catt=true
                ;;
            *)
                if ! $help; then
                    external_taskrc_call $@
                    return
                fi
                # When extra args follow -h, they're treated as a search pattern
                # so we should pass them along
                inner_args+=( $1 )
                ;;
        esac
        shift
    done
    if $catt; then
        taskrc_dir=$PWD taskrc_new --cat
        load=false
    fi
    if $dump; then
        [[ -r $(taskrc_filename $taskrc_dir) ]] || return $(errExit "No current taskrc to dump")
        cat_taskrc $taskrc_dir
        echo "[dump OK for $(taskrc_filename $taskrc_dir) (file is $(taskrc_is_dirty -p) ) ]"  >&2
        load=false
    fi
    if $info; then
        [[ -f ${taskrc_dir}/taskrc.md ]] && ls -l ${taskrc_dir}/taskrc.md
        [[ -f ${taskrc_dir}/taskrc ]] && ls -l ${taskrc_dir}/taskrc
        echo "File is $(taskrc_is_dirty -pd)" 2>/dev/null
        load=false
    fi
    if $new; then
        if ! taskrc_dir=$PWD taskrc_new; then
            return
        fi
        taskrc_dir=$PWD
        load=true
    fi
    if $edit; then
        has_taskrc $taskrc_dir || return $(errExit "No current taskrc to edit")
        (
            cd $taskrc_dir || errExit "Can't cd to $taskrc_dir"
            $EDITOR $(taskrc_filename $taskrc_dir)
        )
        refresh=true
    fi
    if $refresh; then
        if [[ ! -r $(taskrc_filename $taskrc_dir) ]]; then
            if has_taskrc . ;  then
                read -p "No current taskrc to refresh, but there's a taskrc here. Load it? [Y/n]: "
                if [[ $REPLY =~ [yY] ]] || [[ -z $REPLY ]]; then
                    taskrc_v6
                    return
                fi
            else
                read -p "No current taskrc or ./taskrc. Search parent dirs instead? [Y/n]: "
                if [[ $REPLY =~ [yY] ]] || [[ -z $REPLY ]]; then
                    taskrc_v6 -s
                    return
                fi
            fi
            return $(echo "Quit selected.")
        fi
        if ! taskrc_is_dirty ; then
            if ! $force; then
                return $(errExit "[ no refresh, $taskrc_dir/taskrc is unchanged. -f to force. ]")
            fi
        fi
        builtin pushd "$taskrc_dir" >/dev/null
        builtin echo -n "Refreshing $PWD/taskrc: ${BASHPID}["
        register_taskrc "${taskrc_dir}"
        source_taskrc "${taskrc_dir}"
        taskrc_load_time=$(ctimetkr $(taskrc_filename "$taskrc_dir" ))
        builtin echo "]  OK  @$(date)"
        builtin popd >/dev/null
        load=false
    fi

    if $load; then
        # Now it's time to establish $taskrc_dir, having dispensed with other options:
        taskrc_dir=$(taskrc_dir_find $PWD $search_up)

        if [[ ! -r $(taskrc_filename "$taskrc_dir") ]]; then
            local pp=""
            if $search_up; then
                pp=" or its parents, sorry."
            else
                pp=", try -s to search parent dirs."
            fi
            return $(errExit "no taskrc file in ${PWD}${pp}")
        fi
        pushd ${taskrc_dir} &>/dev/null \
            || return $(errExit "Can't cd to ${taskrc_dir}")
        if $help; then
            egrep -v '^$' ./taskrc 2>/dev/null
            echo " >> done help: [${taskrc_dir}/taskrc]"
        fi
        if $load; then
            echo "In [$PWD], loading taskrc into current shell:"
            source_taskrc .
            taskrc_load_time=$(ctimetkr $(taskrc_filename .))
            echo " >> done, $(taskrc_linecount .) lines sourced."
        fi
        popd >/dev/null
    fi
    if $help; then
        local user_search_pattern=".*"
        [[ -n $inner_args ]] \
            && user_search_pattern="${inner_args[@]}"

        taskrc_dir=$taskrc_dir taskrc_help | grep -v '^\s*$' 2>/dev/null | grep -E "$user_search_pattern" | $lesstkr
        load=false
    fi
}

alias taskrc='taskrc_v6'
alias tkr='taskrc_v6'

alias cd_taskrc='cd $taskrc_dir'
alias cd_t='cd $taskrc_dir'
alias tmk='echo "ERROR: run tkr first to load a taskrc context" >&2';

