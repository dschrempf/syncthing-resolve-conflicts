# Resolve sync conflicts

A small bash script that handles synchronization conflicts that
necessarily pop up when using [Syncthing](https://syncthing.net/).
Inspired by
[`pacdiff`](https://wiki.archlinux.org/index.php/Pacman/Pacnew_and_Pacsave#Managing_.pacnew_files)
from Arch Linux.

Be careful with recursive conflicts of the form
`.sync-conflict-XXXXXXXX-XXXXXX.sync-conflict-YYYYYYYY-YYYYYY` as they
are not handled in any special way at the moment.

Files in `/.stversions/` folders will be ignored and consent is asked
for removal.

Non-text files are ignored at the moment and can be removed one by one
if desired.

    syncthing-resolve-conflicts v1.1.0

    Inspired by 'pacdiff'. A simple program to merge or remove sync conflicts.
    'locate' (or 'find', see -f option) is used to find conflicts. In case the
    database is not recent, run 'updatedb'.

    Usage: syncthing-resolve-conflicts [-d DIR] [-f] [-o] [--nocolor]

    General Options:
      -d/--directory DIR  only scan for sync conflicts in the directory DIR
      -f/--find           use find instead of locate; by default, scan the home
                          directory of the current user, but please see the -d
                          option
      -o/--output         print files instead of merging them
      --nocolor           remove colors from output
      -v/--version        print version and exit
      -h/--help           print usage and exit

    Environment Variables:
      DIFFPROG          override the merge program: (default: 'vim -d')

    Example: DIFFPROG=meld syncthing-resolve-conflicts
    Example: syncthing-resolve-conflicts --output
