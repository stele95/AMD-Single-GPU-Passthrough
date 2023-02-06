# AMD Single GPU Passtrough


### Preparations

To prepare, make sure you have virtualization features enabled in your BIOS.

For AMD enable
  • IOMMU
  • NX Mode
  • SVM Mode

For Intel enable
  • VT-d
  • VT-x

Clone the repository by typing:

```
git clone https://github.com/stele95/AMD-Single-GPU-Passtrough && cd AMD-Single-GPU-Passtrough
```

### Preparing GRUB

Preparing GRUB is very simple.

1) Mark the script as executable:
    • AMD: ``chmod +x grub_setup_amd.sh`` 
    • Intel: ``chmod +x grub_setup_intel.sh``
2) Then run the script and follow the instructions:
    • AMD: ``sudo ./grub_setup_amd.sh`` 
    • Intel: ``sudo ./grub_setup_intel.sh``

### Configuring Libvirt

To configure libvirt run the script which configures libvirt and QEMU for you by typing ``sudo ./libvirt_configuration.sh``.
