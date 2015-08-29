# FKEM Image Tools

A simple toolchain which simplifies the process of creating, editing and
maintaining server images. The toolchain is intended to be used with RedHat
systems for the creation of RedHat systems *of the same architecture*.

## Basic usage

To create a basic OS image, download the release RPM for your target system
(i.e. `centos-release-7-0.1406.el7.centos.2.3.x86_64.rpm`) and
run the following command:

```bash
sudo ./img-bootstrap.sh fk-server-test.img centos-release-7-0.1406.el7.centos.2.3.x86_64.rpm
```

This will create and bootstrap the image file `fk-server-test.img` with default
filesystem settings and a few basic packages. To work on your newly created
image, simply run:

```bash
sudo ./img-chroot.sh fk-server-test.img
```

This will open an interactive bash shell on your image.

## Default partition layout

The layout and file systems cannot currently be modified, only partition sizes.
It is as follows:

1. boot partition, formatted as vfat
2. swap partition
3. root partition, formatted as ext4—expand as necessary

    Disk fk-server-minimal.img: 4 GiB, 4294967296 bytes, 8388608 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x156e24e6

    Device                 Boot   Start     End Sectors  Size Id Type
    fk-server-minimal.img1 *       2048  411647  409600  200M  7 HPFS/NTFS/exFAT
    fk-server-minimal.img2       411648 2508799 2097152    1G 82 Linux swap / Solaris
    fk-server-minimal.img3      2508800 8388607 5879808  2.8G 83 Linux
