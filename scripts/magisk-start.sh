#!/system/bin/sh -x

#
# script to start up Magisk-v20.4 from an exploit
# including working permission asking notifications on android 10
# created by j4nn @ xda
#
# must be run within a root shell to work - it has 3 stages:
#
# ./magisk-start.sh -1
# ./magisk-start.sh -2
# ./magisk-start.sh -3
#
# if called like './magisk-start.sh --fresh -2' it would clean up magisk db
# and do a fresh clean start with no defined su permissions
#


FRESH=false
[ "$1" = "--fresh" ] && {
  FRESH=true
  shift
}
if [ ! -e /data/adb/magisk/busybox ]; then
  FRESH=true
fi

case "$1" in
  -1) exec ./magiskpolicy --live --magisk "allow dumpstate * * *" ;;
  -2) STAGE=2 ;;
  -3) STAGE=3 ;;
  *) echo "Usage: magisk-start.sh [--fresh] <-1 | -2 | -3>"; exit 1 ;;
esac

if [ "$STAGE" = "2" ]
then
######################## STAGE 2 ########################

mount -t tmpfs -o mode=755 none /sbin
chcon u:object_r:rootfs:s0 /sbin
chmod 755 /sbin
for f in boot_patch.sh magiskboot magiskinit64 busybox util_functions.sh
do
  cp -a magisk/$f /sbin || { echo "magisk zip is not unpacked!"; umount /sbin; exit 1; }
done

cd /sbin
chmod 755 *

mkdir r
mount -o bind / r
cp -a r/sbin/. /sbin
umount r
rmdir r

mv magiskinit64 magiskinit
./magiskinit -x magisk magisk

ln -s /sbin/magiskinit /sbin/magiskpolicy
ln -s /sbin/magiskinit /sbin/supolicy

if $FRESH; then
  rm -rf /data/adb/magisk.db /data/adb/magisk
  mkdir -p /data/adb/magisk
  chmod 700 /data/adb
  for f in busybox magisk magiskboot magiskinit util_functions.sh boot_patch.sh
  do
    cp -a $f /data/adb/magisk
  done
  chmod -R 755 /data/adb/magisk
  chown -R root:root /data/adb/magisk
fi
chcon -R u:object_r:magisk_file:s0 /data/adb/magisk
rm -f magiskboot util_functions.sh boot_patch.sh

for i in su resetprop magiskhide ; do ln -s /sbin/magisk /sbin/$i ; done

mkdir /sbin/.magisk
chmod 755 /sbin/.magisk
echo "KEEPVERITY=true" > /sbin/.magisk/config
echo "KEEPFORCEENCRYPT=true" >> /sbin/.magisk/config
chmod 000 /sbin/.magisk/config

mkdir -p /sbin/.magisk/busybox ; chmod 755 /sbin/.magisk/busybox
mv busybox /sbin/.magisk/busybox
#/sbin/.magisk/busybox/busybox --install -s /sbin/.magisk/busybox

mkdir -p /sbin/.magisk/mirror ; chmod 000 /sbin/.magisk/mirror
mkdir -p /sbin/.magisk/block ; chmod 000 /sbin/.magisk/block
mkdir -p /sbin/.magisk/modules ; chmod 755 /sbin/.magisk/modules
#ln -s /sbin/.magisk/modules /sbin/.magisk/img
mkdir -p /data/adb/modules ; chmod 755 /data/adb/modules
mkdir -p /data/adb/post-fs-data.d ; chmod 755 /data/adb/post-fs-data.d
mkdir -p /data/adb/service.d ; chmod 755 /data/adb/service.d

#/sbin/magisk --restorecon
chcon -R -h u:object_r:rootfs:s0 /sbin/.magisk
chcon u:object_r:magisk_file:s0 /sbin/.magisk/busybox/busybox

/sbin/magisk --daemon

MP=`pidof magiskd`
while [ -z "$MP" ] ; do sleep 1; MP=`pidof magiskd`; done
echo "$MP" > /sbin/.magisk/escalate
while [ -e /sbin/.magisk/escalate ]; do sleep 1; done


else
######################## STAGE 3 ########################


echo -e '#!/system/bin/sh\n/sbin/magisk --daemon' > /sbin/.magisk/magiskd
chmod 755 /sbin/.magisk/magiskd
chcon u:object_r:dumpstate_exec:s0 /sbin/.magisk/magiskd

SVC=`getprop init.svc.dumpstate`
timeout=10; while [ $timeout -gt 0 ] && ! stop dumpstate ; do sleep 1; timeout=$(($timeout - 1)); done
killall -9 magiskd
stop dumpstate || { echo "failed to stop a service"; exit 1; }

mount -o bind /sbin/.magisk/magiskd /system/bin/dumpstate
start dumpstate
timeout=10
until [ $timeout -le 0 ]
do
  MP=`pidof magiskd`
  [ -n "$MP" ] && break
  sleep 1
  timeout=$(($timeout - 1))
done
stop dumpstate
sleep 1
umount /system/bin/dumpstate
rm -f /sbin/.magisk/magiskd

[ "$SVC" = "running" ] && start dumpstate

rm -f /dev/.magisk_unblock
/sbin/magisk --post-fs-data
timeout=10; until [ -e /dev/.magisk_unblock -o $timeout -le 0 ]; do sleep 1; timeout=$(($timeout - 1)); done

/sbin/magisk --service
sleep 1
/sbin/magisk --boot-complete

chmod 751 /sbin

# su -c 'setenforce 1' &

fi
