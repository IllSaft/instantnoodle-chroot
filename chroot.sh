#!/bin/bash
CONT=/data

for i in dev dev/pts sys proc; do
    mount --bind /$i $CONT/$i
done

chroot=$(which chroot)
PATH="/usr/bin:/usr/sbin:/usr/local/bin" $chroot $CONT $@

for i in dev/pts dev sys proc; do
    umount $CONT/$i
done
