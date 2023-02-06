# AMD Single GPU Passthrough

<details>
  <summary>Hardware specifications at the point of writing this</summary>

    * Operating System: EndeavourOS
    * DE: Gnome
    * Graphics Platform: Wayland
    * GPU Drivers: Mesa/amdgpu
    * Processors: AMD Ryzen 9 5900x
    * Memory: 32 GiB of RAM
    * Graphics Processor: Radeon R9 Fury Sapphire Nitro
    * Motherboard: ASUS Tuf Gaming X570 Plus

</details>

### Preparations

To prepare, make sure you have virtualization features enabled in your BIOS.

* For AMD enable
  - IOMMU
  - NX Mode
  - SVM Mode

* For Intel enable
  - VT-d
  - VT-x

* Clone the repository by typing:

```
git clone https://github.com/stele95/AMD-Single-GPU-Passthrough && cd AMD-Single-GPU-Passthrough
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


### Setting up Windows 11 VM

* Open the virt-manager and prepare Windows iso, also use the ```raw``` image ```virtio``` disk. For Windows 11, you need to have over 54 GB of storage space.

* Use the Q35 chipset and OVMF_CODE.secboot.fd bootloader. 
    
* For Win11 installation, add a TPM emulator in your xml file:
  ```
  <tpm model="tpm-tis">
    <backend type="emulator" version="2.0"/>
  </tpm>
  ```

* Before installing Windows, mount the [virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/) disk first in virt-manager alongside the windows iso
  * <details>
	
      <summary>virt-manager virtio-win.iso mounting</summary>
  
      ![Screenshot from 2022-05-23 15-24-43](https://user-images.githubusercontent.com/32335484/169831867-c173ccae-de54-4bf4-bf7e-e1a29f855f33.png)

    </details>
    
* If installing Windows 11, remove network adapter from VM (NIC :xx:xx:xx) or disconnect from the internet on your host OS before starting the installation because windows forces you to log in to microsoft account. Continue to installing. When the installation is finished and you get to the "Connect to a network screen" when setting up windows for the first time, do the following steps:
    - press Shift + F10 to opet cmd
    - cd oobe
    - BypassNRO.cdm
This will restart your PC and you should see the "I don't have internet" button once you get to the "Connect to a network screen" and you should be able to setup a local account like this

* In order to recognize virtio disk when running installation, don't forget to load virtio driver from virtio-win.iso in the Windows installation.
  * <details>
	
      <summary>Virtio storage driver loading procedure</summary>
  
      ![Screenshot from 2022-05-21 17-31-56](https://user-images.githubusercontent.com/32335484/169829750-a95c0d90-78ed-4b86-ad86-9d6f71557cf7.png)
	
      ![Screenshot from 2022-05-21 17-31-11](https://user-images.githubusercontent.com/32335484/169829787-58e1fa9e-994d-4b45-8726-9e28ce684049.png)
	
      ![Screenshot from 2022-05-21 17-32-27](https://user-images.githubusercontent.com/32335484/169829829-476fd7c4-fa7e-43f5-b0ee-de57a5d0e833.png)

    </details>

* After the installation, boot into Windows and install all virtio drivers from the device manager. You can get drivers from virtio-win.iso. Just load all drivers from virtio-win.iso through ```Add driver``` option in Device Manager

* Disable memballoon in your xml file:
  ```
  <memballoon model="none"/>
  ```
  
* Add these to your XML for improved performance (not sure if this works for Intel). Check the [win11.xml](https://github.com/stele95/AMD-Single-GPU-Passthrough/blob/main/win11.xml) example file for proper placement of each section.
  * <details>
      <summary>XML Configs</summary>

      ```
      Enabling Hyper-V enlightenments (Windows only)

      <hyperv mode='custom'>
        <relaxed state='on'/>
        <vapic state='on'/>
        <spinlocks state='on' retries='8191'/>
        <vpindex state='on'/>
        <runtime state='on'/>
        <synic state='on'/>
        <stimer state='on'/>
        <reset state='on'/>
        <vendor_id state='on' value='Asus'/>  <!-- The value doesn't matter -->
        <frequencies state='on'/>
        <reenlightenment state='off'/>   <!-- We use only one guest. Not fully supported on KVM, disable it. -->
        <tlbflush state='on'/>
        <ipi state='on'/>
        <evmcs state='off'/> 		<!-- We do not use nested KVM in Hyper-v -->
      </hyperv>
      ```

      ```
      KVM features (add this below </hyperv> tag)

      <kvm>
        <hidden state='on'/>
        <hint-dedicated state='on'/>
      </kvm>
      <vmport state='off'/>
      <ioapic driver='kvm'/>
      ```

      ```
      Passthrough mode and policy

      <cpu mode='host-passthrough' check='none' migratable='on'>  <!-- Set the cpu mode to passthrough -->
        <topology sockets='1' dies='1' cores='6' threads='2'/>    <!-- Match the cpu topology. In my case 6c/12t, or 2 threads per each core -->
        <cache mode='passthrough'/>                     <!-- The real CPU cache data reported by the host CPU will be passed through to the virtual CPU -->
        <feature policy='require' name='topoext'/>  <!-- Required for the AMD CPUs -->
        <feature policy='require' name='svm'/>
        <feature policy='require' name='apic'/>         <!-- Enable various features improving behavior of guests running Microsoft Windows -->
        <feature policy='require' name='hypervisor'/>
        <feature policy='require' name='invtsc'/>
      </cpu>                               
      ```

      ```
      Timers

      <clock offset="localtime">
        <timer name="rtc" present="no" tickpolicy="catchup"/>
        <timer name="pit" present="no" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
        <timer name="kvmclock" present="no"/>
        <timer name="hypervclock" present="yes"/>
        <timer name="tsc" present="yes" mode="native"/>
      </clock>
      ```

      ```
      Additional libvirt attributes

      <devices>
      ...
        <memballoon model='none'/>    <!-- Disable memory ballooning -->
        <panic model='hyperv'/>	<!-- Provides additional crash information when Windows crashes -->
      </devices>
     ```

     ```
     Additional QEMU agrs

     You will have to modify virtual machine domain configuration to <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>

     <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
     ...
       </devices>
       <qemu:commandline>
         <qemu:arg value='-overcommit'/>
         <qemu:arg value='cpu-pm=on'/>
       </qemu:commandline>
     </domain>  
     ```

</details>


### Hook Scripts

There is an amazing hook script made by @risingprismtv on gitlab. What this script does is stop your display manager service and all of your running programs, and unhooks your graphics card off of Linux and rehooks it onto the Windows VM.

1) Clone Risngprism's single GPU passthrough gitlab page: ``git clone https://gitlab.com/risingprismtv/single-gpu-passthrough && cd single-gpu-passthrough``.
2) Run the install script as sudo: ``sudo ./install-hooks.sh``.
3) The scripts will successfully install into their required places without issue!


### Editing hooks

1) Edit the hooks script by typing ``sudo nano /etc/libvirt/hooks/qemu``
2) On the line with the if then statement, add in ``|| [[ $OBJECT == "RENAME TO YOUR VM" ]]`` before the ;.
![Screen Capture_select-area_20211204074514](https://user-images.githubusercontent.com/77298458/144715662-f66088d0-d0b7-44f7-a515-2df7419af11e.png)
3) Now you should be good to turn on your VM! On Windows drivers will auto install.


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


## Passthrough (virt-manager)

* Open the virt-manager and add GPU PCI Host devices, both GPU and HDMI Audio devices. Remove DisplaySpice, VideoQXL and other serial devices only from XML file. Also delete all spice related things and usb redirections.
  * ```
    <!-- Remove Display Spice -->
    <graphics type="spice" port="-1" tlsPort="-1" autoport="yes">
      <image compression="off"/>
    </graphics>
    
    <!-- Remove USB Redirection -->
    <redirdev bus="usb" type="spicevmc"/>
    <redirdev bus="usb" type="spicevmc"/>
    
    <!-- Remove Video QXL -->
    <video>
      <model type="qxl"/>
    </video>
    
    <!-- Remove Tablet -->
    <input type="tablet" bus="usb"/>
    
    <!-- Remove console -->
    <console type="pty"/>
    ```
  * <details>
	
      <summary>Adding GPU PCI Host devices</summary>
  
      ![Screenshot from 2022-05-23 15-48-07](https://user-images.githubusercontent.com/32335484/169833957-2c48ff46-bd9c-40a7-95c1-2c3bc72bc72a.png)

    </details>

* Add USB Host devices, like keyboard, mouse... 

* For sound: You can passthrough the PCI HD Audio controler

* If Virtual Network Interface is not present (NIC :xx:xx:xx), add it through Add hardware button
    ```
    Network source: Virtual network 'default' : NAT
    Device model: e1000e (could be different name for you, it was first option)
    ```

* Don't forget to add vbios.rom file inside the win10.xml for the GPU and HDMI host PCI devices, example:
  ```
    ...
    </source>
    <rom file='/var/lib/libvirt/vbios/gpu.rom'/>  <!-- Place between source and address -->
    <address/>
    ...
  ``` 


### Final checks

* You might need to start default network manually:
  ```
  sudo virsh net-start default
  sudo virsh net-autostart default
  ```
  
* Don't forget to edit:
  * /etc/libvirt/qemu.conf
    ```
    user = "yourusername"
    group = "kvm"
    ```

* ```/etc/libvirt/libvirtd.conf``` should be set up like this:
    ```
    unix_sock_group = "libvirt"
    unix_sock_ro_perms = "0777"
    unix_sock_rw_perms = "0770"
    auth_unix_ro = "none"
    auth_unix_rw = "none"
    log_filters = "2:libvirt.domain 1:qemu"
    log_outputs = "1:file:/var/log/libvirt/libvirtd.log"
    ```
    
    
## Logging

* Check all hook logs with ```sudo cat /dev/kmsg | grep libvirt-qemu```

* Check all libvirt logs in ```/var/log/libvirt/libvirtd.log``` file

* Check all qemu logs in ```/var/log/libvirt/qemu/``` directory 
    

### Credits

- BigAnteater for easy guide and scripts for setting up GRUB, libvirt and qemu: https://github.com/BigAnteater/KVM-GPU-Passthrough
- RisingPrismTV for amazing hooks scripts: https://gitlab.com/risingprismtv/single-gpu-passthrough
- Zile995 for detailed guide: https://github.com/Zile995/PinnacleRidge-Polaris-GPU-Passthrough
