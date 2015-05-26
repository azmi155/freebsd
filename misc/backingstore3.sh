#!/bin/sh

#
# Copyright (c) 2009 Peter Holm <pho@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $FreeBSD$
#

# Test unmount of a device that is already gone

# Caused "panic: bundirty: buffer 0xdafaf2c4 still on queue 1"

[ `id -u ` -ne 0 ] && echo "Must be root!" && exit 1

. ../default.cfg

D=$diskimage
export here=`pwd`

m1=$mdstart
m2=$((m1 + 1))
mount | grep "${mntpoint}" | grep -q md$m2 && umount ${mntpoint}$m2
mdconfig -l | grep -q md$m2 &&  mdconfig -d -u $m2
mount | grep "${mntpoint}" | grep -q md$m1 && umount ${mntpoint}$m1
mdconfig -l | grep -q md$m1 &&  mdconfig -d -u $m1
[ -d ${mntpoint}$m1 ] || mkdir -p ${mntpoint}$m1
[ -d ${mntpoint}$m2 ] || mkdir -p ${mntpoint}$m2

dede $D$m1 25m 1 || exit 1

mdconfig -a -t vnode -f $D$m1 -u $m1

bsdlabel -w md$m1 auto
newfs md${m1}${part} > /dev/null 2>&1
mount /dev/md${m1}${part} ${mntpoint}$m1


truncate -s 500M ${mntpoint}$m1/diskimage
mdconfig -a -t vnode -f ${mntpoint}$m1/diskimage -u $m2

bsdlabel -w md$m2 auto
newfs md${m2}${part} > /dev/null 2>&1
mount /dev/md${m2}${part} ${mntpoint}$m2

dd if=/dev/zero of=${mntpoint}$m2/file bs=1m > /dev/null 2>&1

# Reversed umount sequence:
umount -f /dev/md${m1}${part}
umount -f /dev/md${m2}${part}

mount | grep "${mntpoint}" | grep -q md$m2 && umount ${mntpoint}$m2
mdconfig -l | grep -q md$m2 &&  mdconfig -d -u $m2
mount | grep "${mntpoint}" | grep -q md$m1 && umount ${mntpoint}$m1
mdconfig -l | grep -q md$m1 &&  mdconfig -d -u $m1
