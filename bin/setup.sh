#!/bin/bash
# setup.sh for taskrc-kit

die() {
    echo "ERROR: $@" >&2
    exit 1
}

canonpath() {
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")
inode() {
    ( command ls -i "$1" | command awk '{print $1}') 2>/dev/null
}

stub() {
    echo "> > STUB: [$*] < < " >&2
}

is_on_path() {
    local tgt_dir="$1"
    [[ -z $tgt_dir ]] && { true; return; }
    local vv=( $(echo "${PATH}" | tr ':' '\n') )
    for v in ${vv[@]}; do
        if [[ $tgt_dir == $v ]]; then
            return
        fi
    done
    false
}

path_fixup() {
    # Add ~/.local/bin to the PATH if it's not already.  Modify
    # either .bash_profile or .profile honoring bash startup rules.
    local tgt_dir="$1"
    if is_on_path "${tgt_dir}"; then
        return
    fi
    local profile=$HOME/.bash_profile
    [[ -f $profile ]] || profile=$HOME/.profile
    echo 'export PATH=$HOME/.local/bin:$PATH # Added by taskrc-kit-setup.sh' >> ${profile} || die 202
    echo "~/.local/bin added to your PATH." >&2
    reload_reqd=true
}

shrc_fixup() {
    # We must ensure that .bashrc sources our settings script and that the
    # loader symlink is present
    [[ ${TASKRCKIT_LOADER} == 1 ]] && {
        echo "Shell init already sources taskrc-kit loader"
        return
    }
    echo '[[ -n $PS1 && -e ${HOME}/.taskrc-kit-loader ]] && source ${HOME}/.taskrc-kit-loader # Added by taskrc-kit setup.sh' >> ${HOME}/.bashrc
    echo "Added taskrc-kit loader to shell init"
    reload_reqd=true
}


main() {
    reload_reqd=false
    echo "taskrc-kit setup args[$*]"
    if [[ ! -d $HOME/.local/bin/taskrc-kit ]]; then
        if [[ -e $HOME/.local/bin/taskrc-kit ]]; then
            die "$HOME/.local/bin/taskrc-kit exists but is not a directory.  Refusing to overwrite"
        fi
        command mkdir -p $HOME/.local/bin/taskrc-kit || die "Failed creating $HOME/.local/bin/taskrc-kit"
    fi
    if [[ $(inode $Script) -eq $(inode ${HOME}/.local/bin/taskrc-kit/setup.sh) ]]; then
        die "cannot run setup.sh from ${HOME}/.local/bin"
    fi
    builtin cd ${HOME}/.local/bin/taskrc-kit || die "101"
    command rm -rf ./* || die "102"
    [[ -d ${Scriptdir} ]] || die "bad Scriptdir [$Scriptdir]"
    command cp -r ${Scriptdir}/* ./ || die "failed copying from ${Scriptdir} to $PWD"
    builtin cd .. # Now we're in .local/bin
    command ln -sf ./taskrc-kit/taskrc-kit-version.sh ./
    for cmdx in taskrc_register_all.sh taskrc.sh taskrc_help taskrc_new; do
        command ln -sf ./taskrc-kit/${cmdx} ./
    done
    path_fixup "$PWD" || die "102"
    shrc_fixup || die "104"
    $reload_reqd && builtin echo "Shell reload required ('bash -l')" >&2
}

[[ -z $sourceMe ]] && main "$@"
