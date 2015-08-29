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

# Function that prints something helpful
print_usage () {
  cat >&2 <<-EOF
Usage: $0 [OPTION] IMAGE-FILE [COMMAND [ARG]...]

Mounts the IMAGE-FILE and invokes chroot. Note that the presumed partition
table is hardcoded, thus partition 1 and 3 being boot and root, respectively.

OPTION
  -h            Show this help page.
  -m MNT        Use mount point MNT. (default: /mnt)
EOF
  exit 1
}

# Process the command line
while getopts ':hm:' opt; do
  case $opt in
    m)
      MNT="$OPTARG"
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
shift

# Prepare mounts
./fkem-img-mount.sh -m "$MNT" "$IMG"

# Chroot into the mount point—this is where user interaction happens
if [ "$2"x = x ]; then
  chroot "$MNT" "$@"
else
  chroot "$MNT"
fi
# The user exited the chroot, continue with normal operation

# Cleanup mounts
./fkem-img-free.sh "$IMG"
