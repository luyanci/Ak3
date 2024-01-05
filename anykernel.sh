# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
wlan.type=MODULE
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=olive
device.name2=olivelite
device.name3=olivewood
device.name4=olives
device.name5=pine
supported.versions=10 - 11
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=0;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

mount -o rw,remount /vendor

# AnyKernel install
split_boot;

# patchcmdline but disable prebuilt cam since its miui
patch_cmdline "oss.cam_hal" "oss.cam_hal=1";

# patchcmdline but disable dynamic partitions always
patch_cmdline "dynamic_partitions" "dynamic_partitions=0";

if mountpoint -q /data; then
  # Optimize F2FS extension list (@arter97)
  for list_path in $(find /sys/fs/f2fs* -name extension_list); do

    ui_print "F2FS: Optimizing Extension List..."

    hot_count="$(grep -n 'hot file extens' $list_path | cut -d':' -f1)"
    list_len="$(cat $list_path | wc -l)"
    cold_count="$((list_len - hot_count))"

    cold_list="$(head -n$((hot_count - 1)) $list_path | grep -v ':')"
    hot_list="$(tail -n$cold_count $list_path)"

    for ext in $cold_list; do
      [ ! -z $ext ] && echo "[c]!$ext" > $list_path
    done

    for ext in $hot_list; do
      [ ! -z $ext ] && echo "[h]!$ext" > $list_path
    done

    for ext in $(cat $home/f2fs-cold.list | grep -v '#'); do
      [ ! -z $ext ] && echo "[c]$ext" > $list_path
    done

    for ext in $(cat $home/f2fs-hot.list); do
      [ ! -z $ext ] && echo "[h]$ext" > $list_path
    done
  done
fi

# add our lil script
cp -fr $home/module_ext/init.lolz.rc /vendor/etc/init/init.lolz.rc
chmod 644 /vendor/etc/init/init.lolz.rc
chown root.root /vendor/etc/init/init.lolz.rc
chcon u:object_r:vendor_configs_file:s0 /vendor/etc/init/init.lolz.rc

ui_print "F2FS: Replacing fstab.qcom"
cp -fr $home/module_ext/fstab.qcom /vendor/etc/fstab.qcom
chmod 644 /vendor/etc/fstab.qcom

mount -o rw,remount /system
rm -rf /vendor/etc/init/hw/init.qcom.test.rc
ui_print "Cleaning /system/lib/modules..."
ui_print "Cleaning /vendor/lib/modules..."
rm -rf /system/lib/modules/*.ko
rm -rf /vendor/lib/modules/*.ko
ui_print "Cleaned Successfully!!"

ui_print "Adding pronto_wlan.ko Module...."
if [ -d "/vendor/lib/modules" ]; then
ui_print "/vendor/lib/modules Detected!"
cp -fr $home/module_ext/pronto_wlan.ko /vendor/lib/modules/
cp -fr $home/module_ext/README /vendor/lib/modules/
chmod 644 /vendor/lib/modules/pronto_wlan.ko
ui_print "Added pronto_wlan.ko Module Successfully"
elif [ -d "/system/lib/modules" ]; then
ui_print "/system/lib/modules Detected!"
cp -fr $home/module_ext/pronto_wlan.ko /system/lib/modules/
cp -fr $home/anykernel/module_ext/README /system/lib/modules/
chmod 644 $home/system/lib/modules/pronto_wlan.ko
ui_print "Added pronto_wlan.ko Module Successfully"
else
ui_print "Modules directory not found try installing the builtin WLAN build, aborting.."
exit
fi;

flash_boot;
flash_dtbo;

ui_print "Enjoy Using LOLZ KERNEL, Have fun :)"

## end install

# shell variables
#block=vendor_boot;
#is_slot_device=1;
#ramdisk_compression=auto;
#patch_vbmeta_flag=auto;

# reset for vendor_boot patching
#reset_ak;


## AnyKernel vendor_boot install
#split_boot; # skip unpack/repack ramdisk since we don't need vendor_ramdisk access

#flash_boot;
## end vendor_boot install
