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

Run the install script as sudo: ``sudo ./install-hooks.sh``. The scripts will successfully install into their required places without issue!
