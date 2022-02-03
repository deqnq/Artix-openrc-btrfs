#!/bin/sh
############################################################
#                                                          #
#       LAZY ARTIX OPENRC SETUP SCRIPT                     #
#       NO DESKTOP ENVIRONMENT, ONLY BASIC UTILITIES	   #
#	BUT WITH BTRFS INSTEAD				   #
#                                                          #
############################################################

function echo_title() {     echo -ne "\033[1;44;37m${*}\033[0m\n"; }

function splash() {
    local hr
    hr=" **$(printf "%${#1}s" | tr ' ' '*')** "
    echo_title "${hr}"
    echo_title " * $1 * "
    echo_title "${hr}"
    echo
}
## PART 1

printf '\033c'
echo "Welcome to Pixel's artix installer script!"
splash 'Warning! This script assumes you have a separate /home partition !'
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 5/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
lsblk


echo "Enter the drive: "
read drive
cfdisk $drive
gdisk $drive

  echo "Enter the root partition: "
  read root
  mkfs.btrfs $root

  echo "Enter EFI partition: "
  read efi
  mkfs.fat -F32 $efi

mount $root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var

umount /mnt
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@ $root /mnt
mkdir -p /mnt/{boot/efi,home,var}
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@home $root /mnt/home
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@var $root /mnt/var

mount $efi /mnt/boot/efi

basestrap /mnt base base-devel linux linux-firmware openrc btrfs-progs intel-ucode vim
fstabgen -U /mnt >> /mnt/etc/fstab
sed '1,/^##PART 2$/d' setup.sh > /mnt/setup2.sh
chmod +x /mnt/setup2.sh
artix-chroot /mnt ./setup2.sh
exit

##PART 2

printf '\033c'
pacman -S --noconfirm sed artix-archlinux-support
pacman-key --populate archlinux
sed -i "s/^#ParallelDownloads$/ParallelDownloads/" /etc/pacman.conf
sed -i "s/^#[lib32]$/[lib32]/" /etc/pacman.conf
sed -i "s/^#Include = /etc/pacman.d/mirrorlist$/Include = /etc/pacman.d/mirrorlist/" /etc/pacman.conf

echo "# ARCH
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]
Include = /etc/pacman.d/mirrorlist-arch

#[multilib]
#Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
pacman -Sy

ln -sf /usr/share/zoneinfo/Africa/Algiers /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
printf "\n127.0.0.1       localhost\n::1             localhost\n 127.0.1.1       $hostname.localdomain $hostname\n">> /etc/hosts
passwd
pacman --noconfirm -Sy grub efibootmgr grub-btrfs networkmanager networkmanager-openrc network-manager-applet dosfstools linux-headers bluez bluez-openrc bluez-utils
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
#sed -i 's/quiet/pci=noaer/g' /etc/default/grub
#sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

rc-update add NetworkManager default

splash 'Installing important base programs'

pacman -S --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop xf86-video-intel\
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv zathura zathura-pdf-mupdf ffmpeg imagemagick  \
     fzf man-db xwallpaper youtube-dl unclutter xclip maim \
     zip unzip unrar xdotool papirus-icon-theme brightnessctl  \
     ntfs-3g git sxhkd zsh pipewire pipewire-pulse \
     vim neovim arc-gtk-theme rsync firefox dash \
     xcompmgr libnotify dunst slock jq valgrind clang llvm bind rust go \
     rsync pamixer openssh


rc-update add sshd default

rm /bin/sh
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
splash 'Creating a new user with the home directory'
echo "Enter Username: "
read username
useradd -mG wheel $username
passwd $username
ai3_path=/home/$username/setup3.sh
sed '1,/^## PART 3$/d' setup2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit

## PART 3

printf '\033c'
cd $HOME

git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si


echo "SCRIPT IS FINISHED, REBOOT NOW"
echo "Exit the chroot, run: umount -R /mnt"

exit
