#!/usr/bin/bash

# Check for sync conflicts and resolve them.  Idea from the shell
# script 'pacdiff'.

declare -r myname='syncthing-resolve-conflicts.sh'
declare -r myver='1.0.0'

diffprog=${DIFFPROG:-'vim -d'}
USE_COLOR='y'
declare -a ignored
declare -a nontext

plain() {
	(( QUIET )) && return
	local mesg=$1; shift
	printf "    ${mesg}${ALL_OFF}\n" "$@" >&1
}

msg() {
	(( QUIET )) && return
	local mesg=$1; shift
	printf "${GREEN}==>${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&1
}

msg2() {
	(( QUIET )) && return
	local mesg=$1; shift
	printf "${BLUE} ->${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&1
}

ask() {
	local mesg=$1; shift
	printf " ${BLUE}::${ALL_OFF} ${mesg}${ALL_OFF}" "$@" >&1
}

warning() {
	local mesg=$1; shift
    echo
	printf "${YELLOW}==> $(gettext "WARNING:")${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&2
}

error() {
	local mesg=$1; shift
	printf "${RED}==> $(gettext "ERROR:")${ALL_OFF} ${mesg}${ALL_OFF}\n" "$@" >&2
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
	locate -0 -e -b sync-conflict
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

if ! type -p ${diffprog%% *} >/dev/null && (( ! OUTPUTONLY )); then
	error "Cannot find the $diffprog binary required for viewing differences."
	exit 1
fi

warning "Recursive sync conflicts are not properly handled."

# See http://mywiki.wooledge.org/BashFAQ/020.
while IFS= read -u 3 -r -d '' conflict; do
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
    if [[ -z $(file -i "$conflict" | grep text) ]]
    then
		nontext+=("$conflict")
		continue
    fi
    
    # XXX: Recursive sync conflicts lead to problems if they are
    # treated in the wrong order.

    # TODO: Improve pattern match (digits only).

    # Original filename.
    file="${conflict/.sync-conflict-????????-??????/}"

	msg "Sync conflict found: %s" "$conflict"
    # Handle sync conflict if original file exists.
    if [ ! -f "$file" ]
    then
        warning "Original file does not exist for conflict %s." "$conflict"
        ignored+=("$conflict")
        continue
    fi
    msg2 "Original file: %s" "$file"

	if cmp -s "$conflict" "$file"; then
		msg2 "Files are identical, removing..."
		plain "$(rm -v "$conflict")"
	else
		ask "(V)iew, (S)kip, (R)emove sync conflict, (O)verwrite with sync conflict, (Q)uit: [v/s/r/o/q] "
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
    ask "(R)emove ignored files, (Q)uit: [r/q] "
    while read c; do
        case $c in
            q|Q) exit 0 ;;
            r|R) (( ${#ignored[@]} )) && plain "$(rm -v "${ignored[@]}")"; break ;;
            *) ask "Invalid answer.  Try again: [d/q] "; continue ;;
        esac
    done
fi

# Print warning if non-text sync conflicts have been detected and
# delete them one by one if specified.
if [ ! ${#nontext[@]} -eq 0 ]
then
    warning "Some files that are not text have been ignored."
    for f in "${nontext[@]}"
    do
        msg "%s" "$f"
        ask "(R)emove, (S)kip, (Q)uit: [r/s/q] "
        while read c; do
            case $c in
                q|Q) exit 0 ;;
                s|S) break ;;
                r|R) plain "$(rm -v "$f")"; break ;;
                *) ask "Invalid answer.  Try again: [r/s/q] "; continue ;;
            esac
        done
    done
fi

exit 0
