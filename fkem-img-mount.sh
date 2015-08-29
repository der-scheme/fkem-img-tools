#!/usr/bin/env bash

# Ensure failure in case anything goes wrong
set -e

# Callback function that gets executed if the script terminates prematurely and
# correctly unmounts the image file.
on_error () {
  ./fkem-img-free "$IMG"
}
trap on_error ERR

# Define defaults
DO_MOUNT=true
MNT=/mnt

# Function that prints something helpful
print_usage () {
  cat >&2 <<-EOF
Usage: $0 [OPTION] IMAGE-FILE

Creates a loop device for IMAGE-FILE, and, if specified, mounts it at
MOUNT-POINT. Prints the device name (i.e. 'loop0') to stdout.

OPTION
  -h, --help    Shows this help page.
  -m MNT        Mount the image at mount point MNT. Overrides a previous -M
                option. (default: /mnt)
  -M            Do not mount, just create the loop device. Overrides a previous
                -m option.
EOF
  exit 1
}

# Process the command line
while getopts ':hm:M' opt; do
  case $opt in
    m)
      DO_MOUNT=true
      MNT="$OPTARG"
      ;;
    M)
      DO_MOUNT=false
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

# Create loop device
LOOP=$(kpartx -asv "$IMG" | sed -r 's/^.*\/dev\/([^ ]*) [0-9]*$/\1/g' | head -n1)
MAPPER=/dev/mapper/$LOOP
echo $LOOP

if $DO_MOUNT; then
# Prepare mounts
  mkdir -p "$MNT"
  mount ${MAPPER}p3 "$MNT"

  mkdir -p "$MNT/boot"
  mount ${MAPPER}p1 "$MNT/boot"

  mkdir -p "$MNT/dev"
  mount --bind /dev "$MNT/dev"

  mkdir -p "$MNT/proc"
  mount -t proc none "$MNT/proc"

  mkdir -p "$MNT/sys"
  mount -t sysfs none "$MNT/sys"
fi
