#!/usr/bin/env bash

# Ensure failure in case anything goes wrong
set -e

# Callback function that gets executed if the script terminates prematurely and
# correctly unmounts the image file.
on_error () {
  ./fkem-img-free.sh "$IMG"
}
# Note that in this script (only), the trap is set after looping the image.

# Define defaults
IMAGE_SIZE=4G
BOOT_SIZE=200M
SWAP_SIZE=1G

# Function that invokes fdisk and creates the following three partitions:
#   - boot: bootable, exFAT (type 7)
#   - swap: swap (type 82)
#   - root
create_partitions () {
  fdisk "$IMG" <<-EOF
o
n
p
1

+$BOOT_SIZE
t
7
n
p
2

+$SWAP_SIZE
t
2
82
a
1
n
p
3


w
EOF
}

# Function that formats the previously created partitions:
#   - boot: vfat
#   - swap: swap
#   - root: ext4
format_partitions () {
  mkfs.vfat /dev/mapper/${LOOP}p1
  mkswap /dev/mapper/${LOOP}p2
  mkfs.ext4 /dev/mapper/${LOOP}p3
}

# Function that prints something helpful
print_usage () {
  cat >&2 <<-EOF
Usage: $0 [OPTION…] IMAGE-FILE

Creates an empty IMAGE-FILE.

OPTION
  -b SIZE       SIZE of the boot partition, in a format understood by fdisk
                (default: 200M)
  -h, --help    Shows this help page
  -i SIZE       SIZE of the entire image file, in a format understood by fdisk
                (default: 4G)
  -s SIZE       SIZE of the swap partition, in a format understood by fdisk.
                Note that disabling swap is currently unsupported.
                (default: 1G)
EOF
  exit 1
}

# Process the command line
while getopts ':b:s:i:h' opt; do
  case $opt in
    b)
      BOOT_SIZE=$OPTARG
      ;;
    s)
      SWAP_SIZE=$OPTARG
      ;;
    i)
      IMAGE_SIZE=$OPTARG
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

if [ "$1"x = x ]; then
  print_usage
fi

IMG="$1"

fallocate -l "$IMAGE_SIZE" "$IMG"
fallocate -z -l  "$IMAGE_SIZE" "$IMG"
create_partitions

LOOP=$(./fkem-img-mount.sh -M "$IMG")
trap on_error ERR
format_partitions

./fkem-img-free.sh "$IMG"
