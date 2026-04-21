#!/bin/bash -e

# an automated ROM installer
# runtime dependencies: adb, fastboot, usbutils, payload-dumper-go, unzip
# device requirements: bootloader unlocked, USB debugging enabled

TMPA="/tmp/rom_installer"

await_fastboot() {
  until lsusb | grep fastboot > /dev/null 2>&1; do
    sleep 0.5
  done
}

if ! mkdir -pv "${TMPA}"; then
  echo "can't write to ${TMPA}, exiting."
  exit 1
fi

case "${1}" in "")
  printf "${0} [path to rom]\n"
  exit ;;
esac

unzip "${1}" -d "${TMPA}" payload.bin
payload-dumper-go \
  -partitions boot,vendor_boot,dtbo \
  -output "${TMPA}/partitions" \
    "${TMPA}/payload.bin"

# TODO: Is attaining shell access necessary?
if adb shell ':' > /dev/null 2>&1; then
  echo "rebooting to bootloader"
  adb reboot bootloader
fi

await_fastboot

# Format user data
fastboot -w

# TODO: Are different images needed for different devices?
for PART in boot vendor_boot dtbo; do
  fastboot flash "${PART}" "${TMPA}/partitions/${PART}.img"
done

fastboot reboot-recovery > /dev/null 2>&1
echo "Rebooting to recovery."
await_fastboot

cat << EOF

===================
On your device:

-> Apply update
  -> Apply from ADB
===================

EOF

until adb devices | grep sideload > /dev/null 2>&1; do
  sleep 0.5; done
adb sideload "${1}"

case "${2}" in -d|--dirty) ;; *)
  rm -frv "${TMPA}" ;;
esac
