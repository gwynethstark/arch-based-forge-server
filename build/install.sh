#!/bin/bash

# exit script if return code != 0

set -e

# refresh pacman keys since keyservers are unreliable
#count=0
#until pacman-key --refresh || (( count++ >= 6 ))
#do
#    echo "[warn] failed to refresh keys for pacman, retrying in 30 seconds..."
#    sleep 30s
#done

# force refresh of pacman db and install sed
pacman -Sy sed --noconfirm

# configure pacman to not extract certain folders from packages being installed
# this is done as we strip out locale, man, docs etc when we build the arch-scratch image
sed -i '\~\[options\]~a # Do not extract the following folders from any packages being installed\n'\
'NoExtract   = usr/share/locale* !usr/share/locale/en* !usr/share/locale/locale.alias\n'\
'NoExtract   = usr/share/doc*\n'\
'NoExtract   = usr/share/man*\n'\
'NoExtract   = usr/share/gtk-doc*\n' \
'/etc/pacman.conf'

# list all packages that we want to exclude/remove
unneeded_packages="\
filesystem \
cryptsetup \
device-mapper \
dhcpcd \
iproute2 \
jfsutils \
libsystemd \
linux \
lvm2 \
man-db \
man-pages \
mdadm \
netctl \
openresolv \
pciutils \
pcmciautils \
reiserfsprogs \
s-nail \
systemd \
systemd-sysvcompat \
usbutils \
xfsprogs"

# split space separated string into list for install paths
IFS=' ' read -ra unneeded_packages_list <<< "${unneeded_packages}"

# construct string to ensure removal of any packages that might be part of tarball
pacman_remove_unneeded_packages='pacman --noconfirm -Rsc'

for i in "${unneeded_packages_list[@]}"; do
	pacman_remove_unneeded_packages="${pacman_remove_unneeded_packages} ${i}"
done

echo "[info] Removing unneeded packages that might be part of the tarball..."
echo "${pacman_remove_unneeded_packages} || true"
eval "${pacman_remove_unneeded_packages} || true"

echo "[info] Adding required packages to pacman ignore package list to prevent upgrades..."

# add coreutils to pacman ignore list to prevent permission denied issue on Docker Hub - 
# https://gitlab.archlinux.org/archlinux/archlinux-docker/-/issues/32
#
# add filesystem to pacman ignore list to prevent buildx issues with
# /etc/hosts and /etc/resolv.conf being read only, see issue -
# https://github.com/moby/buildkit/issues/1267#issuecomment-768903038
#
sed -i -e 's~#IgnorePkg.*~IgnorePkg = coreutils filesystem~g' '/etc/pacman.conf'

pacman -Syu --noconfirm

echo "[info] installing primary packages..."

# installing go since it is a requirement for Yay
# https://aur.archlinux.org/packages/yay/
pacman -S git supervisor sudo base-devel git go --noconfirm

# adding 'nobody' to primary group 'users'
usermod -g users nobody

# adding 'nobody' to group 'nobody'
usermod -a -G nobody nobody

# set up environment for user 'nobody'
mkdir -p '/home/nobody'
chown -R nobody:users '/home/nobody'
chmod -R 775 '/home/nobody'

# setting home directory for user 'nobody'
usermod -d /home/nobody nobody

# setting shell for user 'nobody'
chsh -s /bin/bash nobody

# allow 'nobody' to run pacman without password
echo 'nobody ALL=NOPASSWD: /usr/sbin/pacman' > /etc/sudoers.d/yay

# clone yay as 'nobody' to home folder and build
su nobody -c "git clone https://aur.archlinux.org/yay.git /home/nobody/yay && cd /home/nobody/yay && makepkg"

# install yay as root
pacman -U /home/nobody/yay/yay-${yay_version}-x86_64.pkg.tar.zst --noconfirm

# remove base devel excluding useful core packages
pacman -Ru $(pacman -Qgq base-devel | grep -v awk | grep -v pacman | grep -v sed | grep -v grep | grep -v gzip | grep -v which | grep -v fakeroot) --noconfirm

# general cleanup to shrink image size
yes|pacman -Scc
pacman --noconfirm -Rns $(pacman -Qtdq) 2> /dev/null || true
rm -rf /var/cache/* \
/var/empty/.cache/* \
/usr/share/locale/* \
/usr/share/man/* \
/usr/share/gtk-doc/* \
/tmp/* \
/home/nobody/* \
/home/nobody/.cache/*

# additional cleanup for base only
rm -rf /root/* \
/var/cache/pacman/pkg/* \
/usr/lib/firmware \
/usr/lib/modules \
/.dockerenv \
/.dockerinit \
/usr/share/info/* \
/README \
/bootstrap