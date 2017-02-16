# Resolve sync conflicts

A small bash script that handles synchronization conflicts that
necessarily pop up when using [Syncthing](https://syncthing.net/).
Inspired by
[`pacdiff`](https://wiki.archlinux.org/index.php/Pacman/Pacnew_and_Pacsave#Managing_.pacnew_files)
from Arch Linux.

Recursive conflicts of the form
`.sync-conflict-XXXXXXXX-XXXXXX.sync-conflict-YYYYYYYY-YYYYYY` are not
handled properly yet and will be ignored.

Files in `/.stversions/` folders will be ignored and consent is asked
for removal.

Non-text files are ignored at the moment and can be removed one by one
if desired.

    syncthing-resolve-conflicts.sh v1.0.0

    Inspired by 'pacdiff'.
    A simple program to merge or remove sync conflicts.
    Locate is used to find conflicts.
    In case the database is not recent, run 'updatedb'.

    Usage: syncthing-resolve-conflicts.sh [-o] [--nocolor]

    General Options:
      -o/--output       print files instead of merging them
      --nocolor         remove colors from output

    Environment Variables:
      DIFFPROG          override the merge program: (default: 'vim -d')

    Example: DIFFPROG=meld syncthing-resolve-conflicts.sh
    Example: syncthing-resolve-conflicts.sh --output
