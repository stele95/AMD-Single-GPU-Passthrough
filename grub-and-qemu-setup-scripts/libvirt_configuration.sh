if [ $EUID -ne 0 ]
	then
		echo "This program must run as root to function." 
		exit 1
fi
echo "This will install and configure libvirt."
sleep 1s
pacman -S libvirt libvirt-glib libvirt-python virt-install virt-manager qemu qemu-arch-extra ovmf vde2 ebtables dnsmasq bridge-utils openbsd-netcat iptables swtpm
sleep 1s
systemctl enable libvirtd
echo "systemctl enable libvirtd"
sleep 1s
systemctl start libvirtd
echo "systemctl start libvirtd"
echo "Now it's time to edit your configs!"
mv /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old
echo "mv /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old"
sleep 1s
echo "What is your username?"
read USERNAME
sleep 1s
echo "Adding $USERNAME to kvm and libvirt groups..."
gpasswd -M $USERNAME kvm
gpasswd -M $USERNAME libvirt
sleep 2s
cp libvirtd.conf /etc/libvirt
echo "cp libvirtd.conf /etc/libvirt"
sleep 1s
echo "libvirt has been successfully configured!"
echo "Time for your QEMU configs!"
sleep 2s
echo "mv /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old"
mv /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old
sleep 1s
echo "cp qemu.conf /etc/libvirt"
cp qemu.conf /etc/libvirt
sleep 1s
systemctl restart libvirtd
echo "QEMU has been successfully configured!"
sleep 3s
exit
