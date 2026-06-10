#!/bin/bash -e

# an automated ROM installer
# runtime dependencies: adb, fastboot, payload-dumper-go, unzip
# device requirements: bootloader unlocked, USB debugging enabled

await_mode() {
  while true; do
    case ${1} in
      fastboot)
        case `fastboot devices` in *fastboot) break ;; esac ;;
      *)
        case `adb devices | tail -n +2 | head -1 | tr '	' '\n' | tail -1` in *${1}) break ;; esac ;;
    esac
    sleep 1
  done
}

TMPA="/tmp/rom_installer"
PART_LIST="boot dtbo vendor_boot vendor_kernel_boot"

if ! mkdir -pv "${TMPA}"; then
  echo "can't write to ${TMPA}, exiting."
  exit 1
fi

case "${1}" in "")
  printf "${0} [path to rom]\n"; exit 1
;; esac

unzip "${1}" -d "${TMPA}" payload.bin
payload-dumper-go -partitions `echo ${PART_LIST} | tr ' ' ','` \
  -output "${TMPA}/partitions" \
    "${TMPA}/payload.bin"

case `adb devices | tail -n +2` in *device)
  echo "rebooting to bootloader"
  adb reboot bootloader
;; esac

await_mode fastboot

fastboot -w
for PART in ${PART_LIST}; do fastboot flash "${PART}" "${TMPA}/partitions/${PART}.img"; done
fastboot reboot-recovery > /dev/null 2>&1; echo "Rebooting to recovery."

await_mode recovery

cat << EOF

===================
On your device:

-> Apply update
  -> Apply from ADB
===================

EOF

while true; do
  case `adb devices` in *sideload*) adb sideload "${1}" *) sleep 1 ;; esac
done

case "${2}" in -d|--dirty) ;; *)
  rm -frv "${TMPA}" ;;
esac
