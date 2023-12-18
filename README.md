# OnePlus 8 Instantnoodle Chroot Scripts for Ubuntu Touch

## Chroot Instructions
### Using System Partition
#### Using the chroot script:
```bash
adb reboot recovery
adb push chroot-files/chroot-log-system.sh /
adb shell
chmod +x ./chroot-log-system.sh
./chroot-log-system.sh
```
### Using Data Partition
#### Using the chroot script:
```bash
adb reboot recovery
adb push chroot-files/chroot-log-data.sh /
adb shell
chmod +x ./chroot-log-data.sh
./chroot-log-data.sh
```