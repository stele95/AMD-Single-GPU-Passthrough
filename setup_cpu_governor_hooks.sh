#!/bin/bash
set -e
if [ $EUID -ne 0 ]
	then
		echo "This program must run as root to function." 
		exit 1
fi
echo "This will configure CPU governor hooks."
cp -r -i hooks /etc/libvirt
chmod +x /etc/libvirt/hooks/*/prepare/begin/cpu_mode_performance.sh
chmod +x /etc/libvirt/hooks/*/release/end/cpu_mode_*.sh
cat qemu_cpu_governor_hooks >> /etc/libvirt/hooks/qemu
echo "CPU governor hooks set up successfully!"
