#!/usr/bin/env bash

# Ensure failure in case anything goes wrong
set -e

# Function that prints something helpful
print_usage () {
    cat >&2 <<-EOF
Usage: $0 IMAGE-FILE

Cleans up after fkem-img-mount.sh. Automatically detects the mount points and
umounts the file systems.
EOF
  exit 1
}

# Process the command line
while getopts ':h' opt; do
  case $opt in
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

# Cleanup mounts. We do this by querying kpartx which will return the loop
# devices for IMG.
DEVS=$(kpartx -ls "$IMG" | awk '{ print $1 }')
while IFS= read -r dev; do
  # Query /proc/mounts for the mount point, and, if found, remove it.
  mp="$(grep $dev /proc/mounts | awk '{ print $2 }' || true)"
  if ! [ "$mp"x = x ]; then
    umount -R "$mp"
  fi

  dmsetup clear $dev
done

# Delete loop device
kpartx -ds "$IMG" > /dev/null
