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
PACKAGE_LIST=

# Function that prints something helpful
print_usage () {
  cat >&2 <<-EOF
Usage: $0 [OPTION] IMAGE-FILE RELEASE-RPM

Bootstraps an image file with a small installation of a RedHat distribution.

OPTION
  -h, --help    Show this help page.
  -m MNT        Use mount point MNT. (default: /mnt)
  -p PKGNAME    Install an additional package with name PKGNAME. Invoke this
                option once per package.
EOF
  exit 1
}

# Process the command line
while getopts ':hm:p:' opt; do
  case $opt in
    m)
      MNT="$OPTARG"
      ;;
    p)
      PACKAGE_LIST="$PACKAGE_LIST $OPTARG"
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
RELEASE_RPM="$2"

# Prepare mounts
LOOP=$(./fkem-img-mount.sh "$IMG" "$MNT")

# Install the release rpm
rpm --root "$MNT" -i $RELEASE_RPM

# We import the GPG keys. Since RPM can't import the debug keys CentOS ships
# with, we exclude those from globbing.
# We also work around the fact that shopt will return a non-zero exit value if
# extglob was disabled previously.
shopt extglob > /dev/null || true
rpm --root "$MNT" --import "$MNT"/etc/pki/rpm-gpg/!(*Debug*)
shopt -u extglob > /dev/null || true

# Install base packages
dnf --assumeyes --installroot="$MNT" install \
  bash \
  basesystem \
  coreutils \
  filesystem \
  grub2 \
  kernel \
  setup \
  sshd \
  vim \
  $PACKAGE_LIST

# Install the bootloader
chroot "$MNT" 'grub2-mkconfig -o /boot/grub2/grub.cfg'
chroot "$MNT" "grub-install /dev/$LOOP"

# Clean up
./fkem-img-free.sh "$IMG"

# Success!
echo
echo "Done."
