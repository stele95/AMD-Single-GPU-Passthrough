if [ $EUID -ne 0 ]
	then
		echo "This program must run as root to function." 
		exit 1
fi
echo "This will configure CPU governor hooks."
cp -r -i hooks /etc/libvirt
echo "CPU governor hooks set up successfully!"
