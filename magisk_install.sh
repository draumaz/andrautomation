#!/bin/sh -e

# an automated magisk installer
# runtime dependencies: adb, fastboot, payload-dumper-go, unzip
# device requirements: unlocked bootloader, USB debugging enabled

case "${1}" in "")
  printf "${0} [path to rom]\n"
  exit ;;
esac

MAGISKVER="27.0"
MAGISKURL="https://github.com/topjohnwu/Magisk/releases/download/v${MAGISKVER}/Magisk-v${MAGISKVER}.apk"

test -e "./Magisk-v${MAGISKVER}.apk" || {
  printf "downloading magisk...\n"
  curl -fLO "${MAGISKURL}"
}

# Retrieve boot.img for currently running ROM for patching
unzip "${1}" payload.bin || exit 1
payload-dumper-go -partitions boot -output "${PWD}" payload.bin
adb push "boot.img" "/sdcard/Download/"

# Install and open Magisk on target device
adb install "`find . -name \*Magisk\*apk\* | tail -1`"
adb shell "monkey -p com.topjohnwu.magisk 1"

printf "\npatch /sdcard/Download/boot.img in Magisk and press enter.\n"
read

# ls -atr sorts newest at the bottom; tail that to get the right file
MAGISKIMG="`adb shell ls -atr /sdcard/Download | grep -i magisk | tail -1`"

adb pull "/sdcard/Download/${MAGISKIMG}"
adb shell "rm -f /sdcard/Download/${MAGISKIMG} /sdcard/Download/boot.img"
adb reboot bootloader

for PART in a b; do fastboot flash boot_$PART "${MAGISKIMG}"; done

rm -fv *.{img,apk,bin}

fastboot reboot
