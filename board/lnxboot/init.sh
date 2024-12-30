#!/bin/sh
# devtmpfs does not get automounted for initramfs
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sys /sys

# use the /dev/console device node from devtmpfs if possible to not
# confuse glibc's ttyname_r().
# This may fail (E.G. booted with console=), and errors from exec will
# terminate the shell, so use a subshell for the test
if (exec 0</dev/console) 2>/dev/null; then
    exec 0</dev/console
    exec 1>/dev/console
    exec 2>/dev/console
fi

###################################################################
auto_mount_esp() {
  #
  # Probe and mount my void linux ESP
  #
  local blkid="$(blkid)" tmout=10

  while [ -z "$blkid" ]
  do
    if ! tmout=$(expr $tmout - 1) ; then
      echo "No suitable boot devices found" 1>&2
      return 1
    fi
    sleep 1
    blkid="$(blkid)"
  done

  echo "$blkid" | (
    oIFS="$IFS"
    IFS=":"
    while read blkdev args
    do
      (echo "$args" | grep 'LABEL="EFI[0-9][0-9]*"') || continue
      mkdir -p "$1"
      mount -r -t vfat $blkdev "$1" && exit 0
    done
    exit 1
  ) || return 1
  return 0
}

read_config() {
  local config="$1" t="$2" count=1

  default=
  timeout=

  exec 3<&0
  exec < $config
  exec 4>/dev/null

  while read keyword args
  do
    case "$keyword" in
    default_selection)
      default="$(echo $args | tr -dc 0-9)"
      ;;
    timeout)
      timeout="$(echo $args | tr -dc 0-9)"
      ;;
    menuentry)
      exec 4> "$t/$count"
      count=$(expr $count + 1)
      echo "$args" | xargs | tr -d \"\{ 1>&4
      ;;
    loader|initrd|options)
      echo "$keyword $args" 1>&4
      ;;
    esac
  done
  exec 0<&3 4>&- 3<&-

  if [ $count -eq 1 ] ; then
    echo "No menu entries found" 1>&2
    return 1
  fi
  :
}

show_menu() {
  local t="$1"

  # Create the menu
  if [ -n "$timeout" ] ; then
    # Countdown...
    local default_kernel="$(head -1 "$t/$default")"
    while :
    do
      dialog --timeout 1 --aspect 30 --msgbox \
	"Booting $default_kernel
	in... $timeout
	(Press ENTER for menu)" \
	0 0 && break

      timeout=$(expr $timeout - 1) || :
      if [ $timeout -lt 1 ] ; then
        tag=$default
	return 0
      fi
    done
  fi
  # Create the menu
  set - --no-cancel
  [ -n "$default" ] && set - "$@" --default-item "$default"
  set - "$@" --menu "Boot menu" 0 0 0

  for i in $(ls -1 $t)
  do
    set - "$@" "$i" "$(head -1 "$t/$i")"
  done

  tag=$(dialog "$@" 3>&1 1>&2 2>&3) || tag=$default
}

boot_menu() {
  local esp="$1" t="$2"

  read_config "$esp/EFI/BOOT/refind.conf" "$t" || return $?

  # Dump config
  echo default: $default
  echo timeout: $timeout
  for i in $(ls -1 $t)
  do
    echo -n $i:
    cat "$t/$i"
  done

  show_menu "$t"
  clear

  echo "tag: $tag"
  kernel=$(awk '$1 == "loader" { $1 ="" ; print substr($0,2) }' "$t/$tag")
  initrd=$(awk '$1 == "initrd" { $1 ="" ; print substr($0,2) }' "$t/$tag")
  options=$(awk '$1 == "options" { $1 ="" ; print substr($0,2) }' "$t/$tag" | sed -e 's/^"//' -e 's/"$//')

  echo kernel: $kernel
  echo initrd: $initrd
  echo options: $options

  (
    set -x
    kexec \
	-l "$esp$kernel" \
	--initrd="$esp/$initrd" \
	--command-line "$options"
    umount "$esp" || :
    kexec -e
  )
}

(
  set -euf
  ( set -o pipefail 2>/dev/null) && set -o pipefail || :

  esp=/boot
  auto_mount_esp "$esp" || exit 1

  t=$(mktemp -d)
  trap "exit 1" INT
  trap "rm -rf $t" EXIT

  boot_menu "$esp" "$t" || :
  rm -rf "$t"
)
echo "============================================="
echo "Boot error"
echo "============================================="
exec /bin/sh -il
exec /sbin/init "$@"








