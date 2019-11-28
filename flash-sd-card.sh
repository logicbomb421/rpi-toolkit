#! /usr/bin/env bash
set -e

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

case "$(uname -s)" in
  Linux) ;;
  Darwin)
    function dd() {
      # Homebrew links these with 'g' prefixes to avoid
      # overwriting the builtin commands.
      gdd "$@"
    }
  ;;
  *) echo "Unknown OS: $OS" && exit 1 ;;
esac

while getopts ":d:i:Ep:" opt; do
  case ${opt} in
    d ) DEVICE="${OPTARG}" ;;
    i ) IMAGE_FILE="${OPTARG}" ;;
    E ) NO_EJECT=1 ;;
    p ) UNMOUNT_PARTITION="${OPTARG}" ;;
    \? ) echo "Invalid Option: -$OPTARG" 1>&2 && exit 1 ;;
    : ) echo "Invalid Option: -$OPTARG requires an argument" 1>&2 && exit 1 ;;
  esac
done
shift $((OPTIND -1))

if [[ -z "$DEVICE" ]]; then
  echo "Must specify device" && exit 1
fi

if [[ ! -f "$IMAGE_FILE" ]]; then
  echo "Must specify valid image file" && exit 1
fi 

step=1
function say() {
  echo ""
  echo "#####################################"
  echo "##  ${step}. $1"
  echo "#####################################"
  echo ""
  let "step++"
}

echo ""
printf \
  "Device:%s\nImage:%s\nUnmount Partition:%s\n" \
  "$DEVICE" "$IMAGE_FILE" ${UNMOUNT_PARTITION:-None} \
  | column -s':' -t -c 2 -x
echo ""
read -r -e -n1 \
  -p "Run? [y/n] (n): " \
  confirm_reply
case "$confirm_reply" in
  y|Y);;
  *) exit ;;
esac

if [[ -n "$UNMOUNT_PARTITION" ]]; then
  say "Unmounting $UNMOUNT_PARTITION"
  diskutil unmount "$UNMOUNT_PARTITION"
fi

say "Copying image to ${DEVICE}"
dd bs=1M if="$IMAGE_FILE" of="$DEVICE" conv=sync status=progress

say "Enabling SSH on boot"
sleep 3
touch /Volumes/boot/ssh
echo "done"

say "Copying newpi init script"
cp "${SCRIPT_PATH}/newpi.sh" /Volumes/boot/
echo "done"

if [[ "$NO_EJECT" != 1 ]]; then
  diskutil eject "$DEVICE"
fi

echo "Image ready"
