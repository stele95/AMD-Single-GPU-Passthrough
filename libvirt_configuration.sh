echo "This will install and configure libvirt."
sleep 1s
sudo pacman -S --needed libvirt libvirt-glib libvirt-python virt-install virt-manager qemu-desktop ovmf vde2 ebtables dnsmasq bridge-utils openbsd-netcat iptables swtpm
sleep 1s
echo "Editting libvirtd.conf"
echo "mv /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old"
sudo mv /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old
sleep 1s
echo "Adding $USER to kvm and libvirt groups..."
sudo usermod -aG kvm,libvirt $USER
sleep 2s
echo "cp libvirtd.conf /etc/libvirt"
sudo cp libvirtd.conf /etc/libvirt
sudo sleep 1s
echo "libvirt has been successfully configured!"
echo "Edittin QEMU configs"
sleep 2s
echo "mv /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old"
sudo mv /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old
sleep 1s
echo "cp qemu.conf /etc/libvirt"
sudo cp qemu.conf /etc/libvirt
sleep 1s
echo "systemctl enable --now libvirtd"
sudo systemctl enable --now libvirtd
echo "QEMU has been successfully configured!"
sleep 3s
exit
