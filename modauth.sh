#!/bin/sh -e

if ! which zip > /dev/null 2>&1; then
  echo "[$0] zip missing, quitting"
  exit 1
fi

case "${name}" in "")
  read -p 'name: ' name ;;
esac
case "${version}" in "")
  read -p 'version: ' version ;;
esac
case "${versionCode}" in "")
  read -p 'versionCode: ' versionCode ;;
esac
case "${author}" in "")
  read -p 'author: ' author ;;
esac
case "${description}" in "")
  read -p 'description: ' description ;;
esac

cat << EOF
name: "${name}"
version: "${version}"
versionCode: "${versionCode}"
author: "${author}"
description: "${description}"

script from service.sh:
`cat service.sh`

if everything looks good, press enter.
otherwise, force close this script and resupply variables.
EOF

case "${MODAUTH_FORCE}" in 1) ;; *) read -r ;; esac

cat > module.prop << EOF
name="${name}"
version="${version}"
versionCode="${versionCode}"
author="${author}"
description="${description}"
EOF

mkdir -p META-INF/com/google/android
echo "#MAGISK" > META-INF/com/google/android/updater-script
cat > META-INF/com/google/android/update-binary << EOF
#!/sbin/sh

#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=$2
ZIPFILE=$3

mount /data 2>/dev/null

[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk

install_module
exit 0
EOF

cat > service_real.sh << EOF
#!/system/bin/sh
MODDIR=\${0%/*}
MNAME=\$(basename \$MODDIR)

sleep 20
`cat service.sh`
EOF

rm -f service.sh
mv -f service_real.sh service.sh

zip -r "${name}-${versionCode}.zip" service.sh module.prop META-INF

echo; echo "all done! module zip: $PWD/${name}-${versionCode}.zip"
