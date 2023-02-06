# AMD Single GPU Passtrough


### Preparations

To prepare, make sure you have virtualization enabled in your BIOS.

For AMD this could be done by enabling

  • IOMMU
  • NX Mode
  • SVM Mode

For Intel, just enable

  • VT-d
  • VT-x

Clone the repository by typing:

```
git clone https://github.com/stele95/AMD-Single-GPU-Passtrough && cd AMD-Single-GPU-Passtrough
```

### Preparing GRUB

Preparing GRUB is very simple.

1) Mark the script as executable: for AMD: ``chmod +x grub_setup_amd.sh`` for Intel: ``chmod +x grub_setup_intel.sh``.
2) Then run the script: AMD: ``sudo ./grub_setup_amd.sh`` Intel: ``sudo ./grub_setup_intel.sh``.
3) Then just follow the instructions in script!

### Configuring Libvirt

To configure libvirt run the script which configures libvirt and QEMU for you by typing ``sudo ./libvirt_configuration.sh``.
