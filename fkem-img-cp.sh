#!/usr/bin/env bash

# Ensure failure in case anything goes wrong
set -e

# Callback function that gets executed if the script terminates prematurely and
# correctly unmounts the image file.
on_error () {
  ./fkem-img-free.sh "$IMG"
}
trap on_error ERR

# Define defaults
MNT=/mnt
CP_OPTIONS='-L'

# Function that prints something helpful
print_usage () {
    cat >&2 <<-EOF
Usage: $0 [IMAGE-FILE:]SOURCE… [IMAGE-FILE:]TARGET

Copies from SOURCE to TARGET. This is a wrapper around cp which can also copy
from and to destinations on an image file. Automatically follows symlinks.

Caveat: For all sources and targets, only one IMAGE-FILE is supported.

EXAMPLES
  $0

OPTION
  -h            Show this help page.
  -m MNT        Use mount point MNT. (default: /mnt)
  -i            Interactive mode, prompt before overwrite. Overrides a previous
                -n option.
  -n            Don't overwrite existing files. Overrides a previous -i option.
  -r, -R        Copy recursively.
  -u            Copy only when SOURCE is newer than the target, or when the
                target is missing.
EOF
  exit 1
}

# Process the command line
while getopts ':hm:inrRu' opt; do
  case $opt in
    m)
      MNT="$OPTARG"
      ;;
    i)
      CP_OPTIONS="${CP_OPTIONS}i"
      ;;
    n)
      CP_OPTIONS="${CP_OPTIONS}n"
      ;;
    r|R)
      CP_OPTIONS="${CP_OPTIONS}R"
      ;;
    u)
      CP_OPTIONS="${CP_OPTIONS}u"
      ;;
    h)
      print_usage
      ;;
    ?)
      shift $(($OPTIND - 1))
      if ! [ "$1" = '--help' ]; then
        echo -e "Invalid option: -$OPTARG\n" >&2
      fi

      print_usage
      ;;
    :)
      echo -e "Option -$OPTARG requires an argument.\n" >&2
      print_usage
      ;;
  esac
done
shift $(($OPTIND - 1))
IMG="$1"