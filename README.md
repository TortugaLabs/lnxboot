# BR External - LNXBOOT

This is a [buildroot][br2] external tree to build a linux boot
kernel.

It has been tested with [buildroot][br2] `2024.02.9`.

## Pre-requisites

As one of the steps in [buildroot][br2] it will build its own `fakeroot`
command.  This does not work in [voidlinux][void] with musl runtime.  You
must either switch to [voidlinux][void] with glibc or
setup a `glibc` environment within your [voidlinux][void] installation.

Preparing a [voidlinux][void] glibc system within musl runtime:

```bash
sudo env XBPS_ARCH=x86_64 xbps-install \
		--repository=https://repo-default.voidlinux.org/current  \
        -r /glibc -S \
        base-voidstrap base-devel ncurses-devel rsync wget cpio mtools
```

You must also install the following package build dependancies:

```text
base-devel ncurses-devel rsync wget cpio
```

For testing images with qemu you may also need:

- mtools
- virt-manager-tools
- virt-viewer

These do not need to be part of the glibc environment.

## Setting up Buildroot

[buildroot][br2] is distributed via a git repository.  From this
repository you can select the version that you want to use.

Fetch [buildroot][br2]:

```bash
git clone  https://git.buildroot.net/buildroot
cd buildroot
git co -b dev 2024.02.9
```
I have only tested version `2024.02.9`.  The [buildroot][br2] project has a __LTS__
schema where the `YYYY.02` releases are considered for long term support/more stable.

## Building out-of-tree

Create an empty directory and configure it to use [buildroot][br2]
and the lnxboot external tree.

```bash
mkdir BUILD_DIR
cd BUILD_DIR
glibc make O=$(pwd) BR2_EXTERNAL=_path_to_lnxboot_ext_dir_-C _path_to_buildroot_ lnxboot_defconfig
```

From here on you can start using the out-of-tree build environment.

## Build operations

### Compiling

To compile the kernel and root image:

```bash
glibc make
```

You will find in `images` of two files:

- bzImage
- rootfs.cpio.gz

These can be used in a boot environment.

### Testing

To test in `qemu` run:

```bash
make run-qemu
```
I do not use `glibc` environment here as it is not needed.

### Customizing

To customize things the following commands are available:

- `glibc make menuconfig` - Configures [buildroot][br2]
- `glibc make linux-menuconfig` - Configures the Linux kernel
- `glibc make busybox-menuconfig` - Configures busybox

### Saving configuration changes

```bash
glibc make lnxboot-update
```

This updates the lnxboot git tree.

## TODO

- setfont
- GUI python3 + curses

  [br2]: https://buildroot.org/downloads/manual/manual.html
  [void]: https://voidlinux.org/
