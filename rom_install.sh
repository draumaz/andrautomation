#!/bin/sh -e

# an automated ROM installer
# runtime dependencies: adb, fastboot, payload-dumper-go, unzip
# device requirements: bootloader unlocked, USB debugging enabled

case "${1}" in "")
  printf "${0} [path to rom]\n"
  exit ;;
esac

unzip "${1}" payload.bin

payload-dumper-go \
  -partitions boot,vendor_boot,dtbo \
  -output "${PWD}" \
    payload.bin

rm -fv payload.bin

fastboot -w

for PART in boot vendor_boot dtbo; do
  fastboot flash "${PART}" "${PART}.img"
done

fastboot reboot-recovery

printf "\n[press enter to apply update from adb]: "
read

# Apply ROM to target device
adb sideload "${1}"

rm -fv *.bin *.img
