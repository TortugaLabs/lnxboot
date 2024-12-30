#!/bin/sh
#
# Create a USB from ISO
#
set -euf
(set -o pipefail 2>/dev/null) && set -o pipefail
MAXPART=8192 # only use 8G of partitioned space
mydir=$BR2_EXTERNAL_LNXBOOT_PATH/board/lnxboot

. "$mydir/lib.sh"
saved_args="$(print_args -1 "$@")"
refind_ver=0.14.2
refind_zip=refind-bin-$refind_ver.zip

prep_image() {
  #
  # Create image file
  #
  fallocate -l "$img_sz" "$img"

  # Create partitions
  sfdisk "$img" <<-_EOF_
	label: dos
	;${efi_size};c;*
	_EOF_

  local part_data=$(
    t=$(mktemp -d) ; (
      ln -s "$(readlink -f "$img")" "$t/PART"
      sfdisk -d "$t/PART" | tr -d , | sed -e 's/= */=/g'
    ) || rc=$?
    rm -rf "$t"
    exit ${rc:-0}
  )
  local \
    sector_size=$(echo "$part_data" | awk '$1 == "sector-size:" { print $2 }')
    part_opts=$(echo "$part_data" | grep '/PART1 :' | cut -d: -f2-)
  local \
    part_start=$(check_opt start $part_opts) \
    part_size=$(check_opt size $part_opts)
  local offset=$(expr $part_start '*' $sector_size)

  mkfs.vfat \
	-F 32 \
	-n "$efi_label" \
	-S $sector_size --offset $part_start \
	-v "$img"  $(expr $part_size '*' $sector_size / 1024)

  mtools_img="${img}@@${offset}"
  mmd -i "$mtools_img" "::EFI"
}



main() {
  local serial=false
  local efi_label=EFI$$ efi_size=512M

  while [ $# -gt 0 ]
  do
    case "$1" in
    --serial) serial=true ;;
    --efi-label=*) boot_label=${1#--efi-label=} ;;
    --efi-size=*) boot_size=${1#--efi-size=} ;;
    *) break ;;
    esac
    shift
  done

  if [ $# -eq 0 ] ; then
    #@@@ mkimg.1.md
    #@ :version: <%VERSION%>
    #@
    (
      sed -e's/#@//' | (
	if type mdcat >/dev/null 2>&1 ; then
	  exec mdcat
	else
	  cat
	fi
      )
    ) 2>&1 <<-'EOF'
	#@ # NAME
	#@
	#@ **mkimg** -- Make QEMU image
	#@
	#@ # SYNOPSIS
	#@
	#@ **mkimg** [_options_]
	#@
	#@ # DESCRIPTION
	#@
	#@ This script creates a QEMU disk image.
	#@
	#@ # OPTIONS
	#@
	#@ - **--serial** : passed to mkmenu to configure serial console.
	#@ - **--efi-label=label** : EFI partition label
	#@ - **--efi-size=size** : EFI partition size
	#@
	EOF
    exit 1
  fi


  bdev="$1"
  if (echo "$bdev" | grep -q ,) ; then
    img_sz=${bdev#*,}
    img=${bdev%,*}
  else
    img="$bdev"
    img_sz=8G
  fi
  imgdir=$(dirname "$img")


  prep_image

  local tmp1=$(mktemp -d) rc=0
  trap 'exit 1' INT
  trap 'rm -rf "$tmp1"' EXIT
  (
    mkdir -p "$tmp1/src"
    mkdir -p "$tmp1/src/EFI"
    unzip -q "$mydir/blobs/$refind_zip" -d "$tmp1"
    cp -a "$tmp1/refind-bin-$refind_ver/refind" "$tmp1/src/EFI/refind"
    mkdir -p "$tmp1/src/EFI/BOOT"
    cp -a "$tmp1/src/EFI/refind/refind_x64.efi" "$tmp1/src/EFI/BOOT/bootx64.efi"
    cp -a "$mydir/refind.conf" "$tmp1/src/EFI/BOOT/refind.conf"

    mkdir -p "$tmp1/src/EFI/tools"
    unzip "$mydir/blobs/ShellBinPkg.zip" \
	  ShellBinPkg/UefiShell/X64/Shell.efi \
	  -d "$tmp1"
    cp -av "$tmp1/ShellBinPkg/UefiShell/X64/Shell.efi" "$tmp1/src/EFI/tools/shell.efi"

    mkdir -p "$tmp1/src/EFI/Linux"
    pwd
    cp -av "$imgdir/bzImage" "$tmp1/src/EFI/Linux/bzImage"
    [ -f "$imgdir/rootfs.cpio.gz" ] && \
      cp -av "$imgdir/rootfs.cpio.gz" "$tmp1/src/EFI/Linux/initrd.img"

    find "$tmp1/src" -maxdepth 1 -mindepth 1 | ( while read src
    do
      mcopy -i "$mtools_img" -s -p -Q -n -m -v "$src" "::"
    done ) 2>&1 | summarize "Writting IMG...DONE"

  ) || rc=$?
  exit $rc

}


main "$@"

#
