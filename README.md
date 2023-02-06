# AMD Single GPU Passtrough


### Preparations

To prepare, make sure you have virtualization features enabled in your BIOS.

For AMD enable
  - IOMMU
  - NX Mode
  - SVM Mode

For Intel enable
  - VT-d
  - VT-x

Clone the repository by typing:

```
git clone https://github.com/stele95/AMD-Single-GPU-Passtrough && cd AMD-Single-GPU-Passtrough
```

### Preparing GRUB

Preparing GRUB is very simple.

1) Mark the script as executable:
    - AMD: ``chmod +x grub_setup_amd.sh`` 
    - Intel: ``chmod +x grub_setup_intel.sh``
2) Then run the script and follow instructions:
    - AMD: ``sudo ./grub_setup_amd.sh`` 
    - Intel: ``sudo ./grub_setup_intel.sh``

### Configuring Libvirt

To configure libvirt run the script which configures libvirt and QEMU by typing ``sudo ./libvirt_configuration.sh``.


### Exporting your ROM

1) Find your GPU's device ID: `lspci -vnn | grep '\[03'`. You should see some output such as the following; the first bit (`09:00.0` in this case) is the device ID.
```
09:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Fiji [Radeon R9 FURY / NANO Series] [1002:7300] (rev cb)
```
1) Run `find /sys/devices -name rom` and ensure the device ID matches.
For example looking at the case above, you'll want the last part before the `/rom` to be `09:00.0`, so you might see something like this (the extra `0000:` in front is fine):
```
/sys/devices/pci0000:00/0000:00:03.1/0000:09:00.0/rom
```
1) For convenience's sake, let's call this PATH_TO_ROM. You can manually set this variable as well, by first becoming root (run `sudo su`) then running `export PATH_TO_ROM=/sys/devices/pci0000:00/0000:00:03.1/0000:09:00.0/rom`
1) Then, still as `root`, run the following commands:
```
echo 1 > $PATH_TO_ROM
mkdir -p /var/lib/libvirt/vbios/
cat $PATH_TO_ROM > /var/lib/libvirt/vbios/gpu.rom
echo 0 > $PATH_TO_ROM
```
1) Run `exit` or press Ctrl-D to stop acting as `root`

### Hook Scripts

This is an amazing hook script made by @risingprismtv on gitlab. What this script does is stop your display manager service and all of your running programs, and unhooks your graphics card off of Linux and rehooks it onto the Windows VM.

1) Clone Risngprism's single GPU passthrough gitlab page: ``git clone https://gitlab.com/risingprismtv/single-gpu-passthrough && cd single-gpu-passthrough``.
2) Run the install script as sudo: ``sudo ./install-hooks.sh``.
3) The scripts will successfully install into their required places without issue!

### Editing hooks
This is usefull for people who want to name their VMs to something other than win10.

1) Edit the hooks script by typing ``sudo nano /etc/libvirt/hooks/qemu``
2) On the line with the if then statement, add in ``|| [[ $OBJECT == "RENAME TO YOUR VM" ]]`` before the ;.
![Screen Capture_select-area_20211204074514](https://user-images.githubusercontent.com/77298458/144715662-f66088d0-d0b7-44f7-a515-2df7419af11e.png)
3) Now you should be good to turn on your VM! On Windows drivers will auto install.


### Credits

- BigAnteater for easy guide and scripts for setting up GRUB, libvirt and qemu: https://github.com/BigAnteater/KVM-GPU-Passthrough
- RisingPrismTV for amazing hooks scripts: https://gitlab.com/risingprismtv/single-gpu-passthrough
- Zile995 for detailed guide: https://github.com/Zile995/PinnacleRidge-Polaris-GPU-Passthrough
