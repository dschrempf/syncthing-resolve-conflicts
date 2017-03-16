#!/usr/bin/env bash

# Check for sync conflicts and resolve them.  Idea from the shell
# script 'pacdiff'.

declare -r myname='syncthing-resolve-conflicts'
declare -r myver='1.0.0'

diffprog=${DIFFPROG:-'vim -d'}
USE_COLOR='y'
declare -a ignored
declare -a nontext

plain() {
    (( QUIET )) && return
    local mesg
    mesg="$1"; shift
    printf "    ${mesg}${ALL_OFF}\n" "$@" >&1
}

msg() {
    (( QUIET )) && return
    local mesg
    mesg="$1"; shift
    # shellcheck disable=SC2059
    printf "${GREEN}==>${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&1
}

msg2() {
    (( QUIET )) && return
    local mesg
    mesg="$1"; shift
    # shellcheck disable=SC2059
    printf "${BLUE} ->${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&1
}

ask() {
    local mesg
    mesg="$1"; shift
    # shellcheck disable=SC2059
    printf " ${BLUE}::${ALL_OFF} ${mesg}${ALL_OFF}" "$@" >&1
}

if [ -n "$(command -v gettext)" ]; then
    translate() {
        gettext "$@"
    }
else
    translate() {
        printf %s "$@"
    }
fi
warning() {
    local mesg
    mesg="$1"; shift
    # shellcheck disable=SC2059
    printf "\n${YELLOW}==> $(translate "WARNING:")${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&2
}

error() {
    local mesg
    mesg="$1"; shift
    # shellcheck disable=SC2059
    printf "${RED}==> $(translate "ERROR:")${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&2
}

usage() {
    cat <<EOF
${myname} v${myver}

Inspired by 'pacdiff'.
A simple program to merge or remove sync conflicts.
Locate is used to find conflicts.
In case the database is not recent, run 'updatedb'.

Usage: $myname [-o] [--nocolor]

General Options:
  -o/--output       print files instead of merging them
  --nocolor         remove colors from output

Environment Variables:
  DIFFPROG          override the merge program: (default: 'vim -d')

Example: DIFFPROG=meld $myname
Example: $myname --output

EOF
}

version() {
    printf "%s %s\n" "$myname" "$myver"
    echo 'Copyright (C) 2017 Dominik Schrempf <dominik.schrempf@gmail.com>'
    echo 'Inspired by "pacdiff".'
}

cmd() {
    case "$(uname -s)" in
        Darwin) locate -0 sync-conflict;;
        *) locate -0 -e -b sync-conflict ;;
    esac
}

while [[ -n "$1" ]]; do
    case "$1" in
        -o|--output)
            OUTPUTONLY=1;;
        --nocolor)
            USE_COLOR='n';;
        -v|-V|--version)
            version; exit 0;;
        -h|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
    shift
done

# Check if messages are to be printed using color.
unset ALL_OFF BOLD BLUE GREEN RED YELLOW
if [[ -t 2 && $USE_COLOR = "y" ]]; then
    # Prefer terminal safe colored and bold text when tput is supported.
    if tput setaf 0 &>/dev/null; then
        ALL_OFF="$(tput sgr0)"
        BLUE="$(tput setaf 27)"
        GREEN="$(tput setaf 2)"
        RED="$(tput setaf 1)"
        YELLOW="$(tput setaf 3)"
    else
        ALL_OFF="\e[1;0m"
        BLUE="\e[1;34m"
        GREEN="\e[1;32m"
        RED="\e[1;31m"
        YELLOW="\e[1;33m"
    fi
fi
readonly ALL_OFF BOLD BLUE GREEN RED YELLOW

if [ -z "$(command -v "${diffprog%% *}")" ] && (( ! OUTPUTONLY )); then
    error "Cannot find the $diffprog binary required for viewing differences."
    exit 1
fi

warning "Recursive sync conflicts are not properly handled."

# See http://mywiki.wooledge.org/BashFAQ/020.
while IFS= read -u 3 -r -d '' conflict; do
    [[ ! -e "$conflict" && ! -L "$conflict" && ! -d "$conflict" ]] && continue
    if (( OUTPUTONLY )); then
        echo "$conflict"
        continue
    fi

    # Ignore backups in '.stversions' folders.
    if [[ "$conflict" = */.stversions/* ]]
    then
        ignored+=("$conflict")
        continue
    fi

    # XXX: Maybe somebody wants to diff special non-text files?

    # Ignore binary files.
    if file -i "$conflict" | grep -qv text
    then
        nontext+=("$conflict")
        continue
    fi

    # XXX: Recursive sync conflicts lead to problems if they are
    # treated in the wrong order.

    # TODO: Improve pattern match (digits only).

    # Original filename.
    file="${conflict/.sync-conflict-????????-??????/}"
    msg "Sync conflict: %s" "$conflict"
    # Handle sync conflict if original file exists.
    if [ ! -f "$file" ]
    then
        warning "Original file does not exist for conflict %s." "$conflict"
        ignored+=("$conflict")
        continue
    fi
    msg2 "Original file: %s" "$file"

    if test "$conflict" -ef "$file"; then
        warning "Original file and conflict file point to the same file. Ignoring conflict."
        continue
    elif cmp -s "$conflict" "$file"; then
        msg2 "Files are identical, removing..."
        plain "$(rm -v "$conflict")"
    else
        ask "(V)iew, (S)kip, (R)emove sync conflict, (O)verwrite with sync conflict, (Q)uit: [v/s/r/o/q] "
        # shellcheck disable=SC2162
        while read c; do
            case $c in
                q|Q) exit 0;;
                r|R) plain "$(rm -v "$conflict")"; break ;;
                o|O) plain "$(mv -v "$conflict" "$file")"; break ;;
                v|V)
                    $diffprog "$conflict" "$file"
                    ask "(V)iew, (S)kip, (R)emove sync conflict, (O)verwrite with sync conflict, (Q)uit: [v/s/r/o/q] "
                    continue ;;
                s|S) break ;;
                *) ask "Invalid answer. Try again: [v/s/r/o/q] "; continue ;;
            esac
        done
    fi
done 3< <(cmd)

# Print warning if files have been ignored and delete them if
# specified.
if [ ! ${#ignored[@]} -eq 0 ]
then
    warning "Some files have been ignored."
    (( ${#ignored[@]} )) && msg "%s" "${ignored[@]}"
    ask "(R)emove all ignored files, (A)sk for each file, (Q)uit: [r/q] "
    # shellcheck disable=SC2162
    while read c; do
        case "$c" in
            q|Q) exit 0 ;;
            a|A)
                for f in "${ignored[@]}"
                do
                    msg "Ignored file: %s" "$f"
                    ask "(R)emove, (S)kip, (Q)uit: [r/s/q] "
                    # shellcheck disable=SC2162
                    while read ci; do
                        case "$ci" in
                            q|Q) exit 0 ;;
                            s|S) break ;;
                            r|R) plain "$(rm -v "$f")"; break ;;
                            *) ask "Invalid answer.  Try again: [r/s/q] "; continue ;;
                        esac
                    done
                done
                ;;
            r|R) (( ${#ignored[@]} )) && plain "$(rm -v "${ignored[@]}")"; break ;;
            *) ask "Invalid answer.  Try again: [d/q] "; continue ;;
        esac
    done
fi

# Print warning if non-text sync conflicts have been detected and
# delete them one by one if specified.
if [ ! ${#nontext[@]} -eq 0 ]
then
    warning "The following files that are non-text:"
    for f in "${nontext[@]}"
    do
        msg "Non-text file: %s" "$f"
        ask "(R)emove, (S)kip, (Q)uit: [r/s/q] "
        # shellcheck disable=SC2162
        while read c; do
            case "$c" in
                q|Q) exit 0 ;;
                s|S) break ;;
                r|R) plain "$(rm -v "$f")"; break ;;
                *) ask "Invalid answer.  Try again: [r/s/q] "; continue ;;
            esac
        done
    done
fi

exit 0
