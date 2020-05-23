#!/system/bin/sh -x

#
# script to unpack Magisk-v20.4.zip and install MagiskManager
# created by j4nn @ xda
#
#
# wget https://github.com/topjohnwu/Magisk/releases/download/v20.4/Magisk-v20.4.zip
#

[ "$1" = "--cleanup" ] && {
	rm -rf magisk magiskpolicy
	exit 0
}

ZIPFILE=${1:-Magisk-v20.4.zip}

if [ ! -d magisk ]; then
	mkdir -p magisk
	cd magisk
	unzip ../$ZIPFILE
	mv META-INF/com/google/android/update-binary arm/magiskboot arm/magiskinit64 common/*.sh .
	sh ./update-binary -x
	pm install -r common/magisk.apk
	rm -rf update-binary META-INF arm chromeos common x86
	cd ..
	ln -s magisk/magiskinit64 magiskpolicy
fi
