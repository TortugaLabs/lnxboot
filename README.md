# BR External - LNXBOOT

This is a [buildroot][br2] external tree to build a linux boot
kernel.

It has been tested with [buildroot][br2] `2024.02.9`.

## Pre-requisites

In [voidlinux][void] if using `musl` run-time, you must switch
to `glibc` or equivalent.  Install the following package
dependancies:

- base-devel
- ncurses-devel
- rsync
- wget
- cpio
- mtools

`mtools` is only need for creating/testing images using `qemu`.

# Setting up buildroot

Get [buildroot][br2] and switch to the correct branch:

```bash
git clone https://git.buildroot.net/buildroot
cd buildroot
git co -b MY_NEW_BRANCH __tag__
```

Use `git tag -l` to list available tags.  LTS tags are named _YEAR_.02._P_.

# Building out-of-tree

```bash
mkdir BUILD_DIR
cd BUILD_DIR
glibc make O=BUILD_DIR BR2_EXTERNA=_path_to_lnxboot_ext_dir_-C _path_to_buildroot_ lnxboot_defconfig
glibc make
```

  [br2]: https://buildroot.org/downloads/manual/manual.html
  [void]: https://voidlinux.org/
