# AMD Single GPU Passthrough

<details>
  <summary>Hardware specifications at the point of writing this</summary>

    * Operating System: EndeavourOS
    * DE: KDE Plasma 6
    * Graphics Platform: Wayland
    * GPU Drivers: Mesa/amdgpu
    * Processors: AMD Ryzen 9 5900x
    * Memory: 32 GiB of RAM
    * Graphics Processor: AsRock 7900XTX Taichi
    * Motherboard: ASUS Tuf Gaming X570 Plus

</details>

### Table of contents
* [Preparations](#preparations)
* [Preparing GRUB](#preparing-grub)
* [Configuring Libvirt](#configuring-libvirt)
* [Setting up Windows VM](#setting-up-windows-vm)
* [Hook scripts](#hook-scripts)
	* [Editing hooks](#editing-hooks)
* [Export GPU ROM](#export-gpu-rom)
* [Passthrough (virt-manager)](#passthrough-virt-manager)
* [Final checks](#final-checks)
* [Improving VM and CPU performance](#improving-vm-and-cpu-performance)
	* [CPU pinning](#cpu-pinning)
	* [CPU Governor](#cpu-governor)
	* [CPU passthrough mode](#cpu-passthrough-mode)
	* [Line-Based vs. Message Signaled-Based Interrupts (MSI)](#line-based-vs-message-signaled-based-interrupts-msi)
	* [Internet improvements](#internet-improvements)
* [EAC games detecting VM](#eac-games-detecting-vm)
* [Logging](#logging)

### Preparations

To prepare, make sure you have virtualization features enabled in your BIOS.

* For AMD enable
  - IOMMU
  - NX Mode
  - SVM Mode

* For Intel enable
  - VT-d
  - VT-x

* Clone the repository:

	```
	git clone https://github.com/stele95/AMD-Single-GPU-Passthrough && cd AMD-Single-GPU-Passthrough
	```


### Preparing GRUB

Preparing GRUB is very simple.

* Run the appropriate script based on your cpu:
    - AMD: ``sudo ./grub_setup_amd.sh`` 
    - Intel: ``sudo ./grub_setup_intel.sh``


### Configuring Libvirt

To configure libvirt run the script which configures libvirt and QEMU by typing ``./libvirt_configuration.sh``.


### Setting up Windows VM

* Open the virt-manager and prepare Windows iso, I used ``sata`` and ``qcow2`` for the disk type. For Windows 11, you need to have over 54 GB of storage space.

* You can use `virtio` disks for supposedly improved performance, but for me regular `sata` felt like it works better. You can read more about it [here](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Virtio_disk) and you'll need drivers from [virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/).

* Use the ``Q35`` chipset and ``x64/OVMF_CODE.secboot.4m.fd`` bootloader.
    
* For Windows 11 installation, add a TPM emulator in your xml file:
  ```
  <tpm model="tpm-tis">
    <backend type="emulator" version="2.0"/>
  </tpm>
  ```
    
* Your VM settings should look similar to this before starting the installation. You can remove all unnecessary devices before starting the installation.

	![VM setup before installation](./images/VM%20setup%20before%20installation.png)
    
* If installing Windows 11, remove the network adapter from the VM (NIC :xx:xx:xx) or disconnect from the internet on your host OS before starting the installation because windows 11 setup forces you to log in with a microsoft account. 
	- Install Windows. 
	- When the installation is finished and you get to the "Connect to a network" screen when setting up windows for the first time, do the following steps:
    	- press Shift + F10 to opet cmd
    	- you might have to click on the cmd window if it doesn't get focused automatically
    	- ``cd oobe``
    	- type in ``BypassNRO.cmd`` and press enter

    This will restart your PC and you should see the "I don't have internet" button once you get to the "Connect to a network" screen and you should be able to setup a local account like this

* Disable memballoon in your xml file:
  ```
  <memballoon model="none"/>
  ```
  
* Add these to your XML for improved performance (not sure if this works for Intel). Check the [win11.xml](./win11.xml) example file for proper placement of each section.
  * XML Configs
      
      - <details>
      	  <summary>Enabling Hyper-V enlightenments (Windows only)</summary>
      	  
		  ```
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
      </details>

      - <details>
		  <summary>KVM features</summary>
		  
		  Add this below `</hyperv>` tag
		  
		  ```
		  <kvm>
		    <hidden state='on'/>
		    <hint-dedicated state='on'/>
		  </kvm>
		  <vmport state='off'/>
		  <ioapic driver='kvm'/>
		  ```
	  </details>
	  
      - <details>
		  <summary>Passthrough mode and policy</summary>

		  ```
		  <cpu mode='host-passthrough' check='none' migratable='on'>  <!-- Set the cpu mode to passthrough -->
		    <topology sockets='1' dies='1' cores='8' threads='2'/>    <!-- Match the cpu topology. In my case 8c/16t, or 2 threads per each core -->
		    <cache mode='passthrough'/>                     <!-- The real CPU cache data reported by the host CPU will be passed through to the virtual CPU -->
		    <feature policy='require' name='topoext'/>  <!-- Required for the AMD CPUs -->
		    <feature policy='require' name='svm'/>
		    <feature policy='require' name='apic'/>         <!-- Enable various features improving behavior of guests running Microsoft Windows -->
		    <feature policy='require' name='hypervisor'/>
		    <feature policy='require' name='invtsc'/>
		  </cpu>                               
		  ```
	  </details>

      
      - <details>
		  <summary>Timers</summary>
		  
		  ```
		  <clock offset="localtime">
		    <timer name="rtc" present="no" tickpolicy="catchup"/>
		    <timer name="pit" present="no" tickpolicy="delay"/>
		    <timer name="hpet" present="no"/>
		    <timer name="kvmclock" present="no"/>
		    <timer name="hypervclock" present="yes"/>
		    <timer name="tsc" present="yes" mode="native"/>
		  </clock>
		  ```
	  </details>

      - <details>
		  <summary>Additional libvirt attributes</summary>

		  ```
		  <devices>
		  ...
		    <memballoon model='none'/>    <!-- Disable memory ballooning -->
		    <panic model='hyperv'/>	<!-- Provides additional crash information when Windows crashes -->
		  </devices>
		 ```
	  </details>

	  - <details>
		  <summary>Additional QEMU agrs</summary>

		  You will have to modify virtual machine domain configuration to ``<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>``

		  ```
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


#### Editing hooks

1) Edit the hooks script located at ``/etc/libvirt/hooks/qemu``
2) On the line with the if then statement change the name to the name of your VM.

	![VM hook name](./images/vm%20hook%20name.png)

3) Now you should be good to turn on your VM! On Windows drivers will auto install.


### Export GPU ROM (Mandatory for 7900XTX, optional for older GPUs if the VM is not starting or shutting down properly)

The best way is to extract it from Windows using GPU-Z and copy that file to ``/var/lib/libvirt/vbios/``. In case you don't have access to Windows installation, try the following steps:

1) Find your GPU's device ID: `lspci -vnn | grep '\[03'`. You should see some output such as the following; the first bit (`09:00.0` in this case) is the device ID.

	```
	09:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Fiji [Radeon R9 FURY / NANO Series] [1002:7300] (rev cb)
	```
	
2) Run `find /sys/devices -name rom` and ensure the device ID matches. For example looking at the case above, you'll want the last part before the `/rom` to be `09:00.0`, so you might see something like this (the extra `0000:` in front is fine):

	```
	/sys/devices/pci0000:00/0000:00:03.1/0000:09:00.0/rom
	```
	
3) For convenience's sake, let's call this PATH_TO_ROM. You can manually set this variable as well, by first becoming root (run `sudo su`) then running `export PATH_TO_ROM=/sys/devices/pci0000:00/0000:00:03.1/0000:09:00.0/rom`

4) Then, still as `root`, run the following commands:

	```
	echo 1 > $PATH_TO_ROM
	mkdir -p /var/lib/libvirt/vbios/
	cat $PATH_TO_ROM > /var/lib/libvirt/vbios/gpu.rom
	echo 0 > $PATH_TO_ROM
	```
	
5) Run `exit` to stop acting as `root`


### Passthrough (virt-manager)

* Open the virt-manager and remove DisplaySpice, VideoQXL and other serial devices from XML file. Also delete all spice related things and usb redirections.
   ```
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
    
* Add GPU and HDMI/DP Audio PCI Host devices. Make sure to add all of them from the same bus as the GPU
  
	![Adding GPU](./images/Adding%20GPU.png)

* Add USB Host devices, like keyboard, mouse... 

* For sound: You can passthrough the PCI HD Audio controller. BUT, be carefull. Ryzen 3000 and above apparently have problems when passing HD Audio Controller and USB controller that's on the same PCI bus as audio controller. For more info, look at [this](https://www.reddit.com/r/VFIO/comments/eba5mh/workaround_patch_for_passing_through_usb_and/?sort=new). If you are having issues with audio controller passthrough, you can set your audio up differently. Use [this](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_audio_from_virtual_machine_to_host_via_PulseAudio) for `PulseAudio` or [this](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_audio_from_virtual_machine_to_host_via_JACK_and_PipeWire) for `PipeWire`.

* If Virtual Network Interface is not present (NIC :xx:xx:xx), add it through Add hardware button
    ```
    Network source: Virtual network 'default' : NAT
    Device model: e1000e (could be different name for you, it was first option)
    ```

* If you need to export your GPU ROM, don't forget to add vbios.rom file inside the win11.xml (or whatever your VM's name is) for the GPU and HDMI host PCI devices, example:
  ```
    ...
    </source>
    <rom file='/var/lib/libvirt/vbios/gpu.rom'/>  <!-- Place between source and address -->
    <address/>
    ...
  ``` 
  
  Also, for 7900XTX, make sure to disable Resize BAR in your BIOS and in the Virtual Manager (ROM BAR option on the PCI Device)


### Final checks

* You might need to start the default network manually:
  ```
  sudo virsh net-start default
  sudo virsh net-autostart default
  ```
  
* Don't forget to edit `/etc/libvirt/qemu.conf`:
    ```
    user = "yourusername"
    group = "kvm"
    ```

* ``/etc/libvirt/libvirtd.conf`` should be set up like this:
    ```
    unix_sock_group = "libvirt"
    unix_sock_ro_perms = "0777"
    unix_sock_rw_perms = "0770"
    auth_unix_ro = "none"
    auth_unix_rw = "none"
    log_filters = "2:libvirt.domain 1:qemu"
    log_outputs = "1:file:/var/log/libvirt/libvirtd.log"
    ```
    
* Check if CPU and RAM configurations are properly set


### Improving VM and CPU performance

#### CPU pinning
	
- It is a general recommendation to leave core 0 from all CCXs to the host.
- Since I have a 5900x with 12c/24t, I will be passing 10c/20t with a setup of 5c/10t from the same CCX to the VM, so it will be two CCXs with 5c/10t. The rest will be pinned to the host. If you have a different CPU, this config will not apply to you, but you can check for a more detailed information on how to set this up [here](https://github.com/bryansteiner/gpu-passthrough-tutorial#----cpu-pinning) and [here](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_topology). If using ``lstopo`` and you have ``PU#`` and ``P#`` for threads, look at the ``P#`` value for the thread id.
- You can also use ``virsh capabilities`` and look for a ``<cache>`` part, this will tell you how your cores/threads are separated per L3 cache. It should look something like this:
	
	```
	<cache>
	  <bank id='0' level='3' type='both' size='32' unit='MiB' cpus='0-5,12-17'/>
	  <bank id='1' level='3' type='both' size='32' unit='MiB' cpus='6-11,18-23'/>
	</cache>
	```
	
- Try to match the L3 cache core assignments by adding fake cores that won't be enabled. Take a look at my code bellow and pay attention to ``vcpu``s with ``enabled="no"``. Those are fake cores that will be disabled, but are present so the assignment of cores per L3 cache is correct. For this, you will need to use [Coreinfo](https://learn.microsoft.com/en-us/sysinternals/downloads/coreinfo) inside the VM and figure out how many fake cores do you need and where do you need to put them.
	
- <details>
	<summary>The code for my setup</summary>
	
	```
	<vcpu placement="static" current="20">26</vcpu>
	<vcpus>
		<vcpu id="0" enabled="yes" hotpluggable="no"/>
		<vcpu id="1" enabled="yes" hotpluggable="no"/>
		<vcpu id="2" enabled="yes" hotpluggable="no"/>
		<vcpu id="3" enabled="yes" hotpluggable="no"/>
		<vcpu id="4" enabled="yes" hotpluggable="no"/>
		<vcpu id="5" enabled="yes" hotpluggable="no"/>
		<vcpu id="6" enabled="yes" hotpluggable="no"/>
		<vcpu id="7" enabled="yes" hotpluggable="no"/>
		<vcpu id="8" enabled="yes" hotpluggable="no"/>
		<vcpu id="9" enabled="yes" hotpluggable="no"/>
		<vcpu id="10" enabled="no" hotpluggable="yes"/>
		<vcpu id="11" enabled="no" hotpluggable="yes"/>
		<vcpu id="12" enabled="no" hotpluggable="yes"/>
		<vcpu id="13" enabled="no" hotpluggable="yes"/>
		<vcpu id="14" enabled="no" hotpluggable="yes"/>
		<vcpu id="15" enabled="no" hotpluggable="yes"/>
		<vcpu id="16" enabled="yes" hotpluggable="yes"/>
		<vcpu id="17" enabled="yes" hotpluggable="yes"/>
		<vcpu id="18" enabled="yes" hotpluggable="yes"/>
		<vcpu id="19" enabled="yes" hotpluggable="yes"/>
		<vcpu id="20" enabled="yes" hotpluggable="yes"/>
		<vcpu id="21" enabled="yes" hotpluggable="yes"/>
		<vcpu id="22" enabled="yes" hotpluggable="yes"/>
		<vcpu id="23" enabled="yes" hotpluggable="yes"/>
		<vcpu id="24" enabled="yes" hotpluggable="yes"/>
		<vcpu id="25" enabled="yes" hotpluggable="yes"/>
	</vcpus>
	<cputune>
		<vcpupin vcpu="0" cpuset="1"/>
		<vcpupin vcpu="1" cpuset="13"/>
		<vcpupin vcpu="2" cpuset="2"/>
		<vcpupin vcpu="3" cpuset="14"/>
		<vcpupin vcpu="4" cpuset="3"/>
		<vcpupin vcpu="5" cpuset="15"/>
		<vcpupin vcpu="6" cpuset="4"/>
		<vcpupin vcpu="7" cpuset="16"/>
		<vcpupin vcpu="8" cpuset="5"/>
		<vcpupin vcpu="9" cpuset="17"/>
		<vcpupin vcpu="16" cpuset="7"/>
		<vcpupin vcpu="17" cpuset="19"/>
		<vcpupin vcpu="18" cpuset="8"/>
		<vcpupin vcpu="19" cpuset="20"/>
		<vcpupin vcpu="20" cpuset="9"/>
		<vcpupin vcpu="21" cpuset="21"/>
		<vcpupin vcpu="22" cpuset="10"/>
		<vcpupin vcpu="23" cpuset="22"/>
		<vcpupin vcpu="24" cpuset="11"/>
		<vcpupin vcpu="25" cpuset="23"/>
		<emulatorpin cpuset="0,6,12,18"/>
	</cputune>
	```

</details>

- Make sure to update the ``<cpu>`` topology to match the number of cores and threads you are passing to the VM. For my setup, it looks like this:

	```
	<cpu mode='host-passthrough' check='none' migratable='on'>  <!-- Set the cpu mode to passthrough -->
		<!-- 13c/26t because 3c/6t are disabled and 10c/20t are used to match the proper L3 cache placement -->
		<topology sockets='1' dies='1' cores='13' threads='2'/>
		<cache mode='passthrough'/>                     <!-- The real CPU cache data reported by the host CPU will be passed through to the virtual CPU -->
		<feature policy='require' name='topoext'/>  <!-- Required for the AMD CPUs -->
		<feature policy='require' name='svm'/>
		<feature policy='require' name='apic'/>         <!-- Enable various features improving behavior of guests running Microsoft Windows -->
		<feature policy='require' name='hypervisor'/>
		<feature policy='require' name='invtsc'/>
	</cpu>  
	```


#### CPU Governor

This tweak takes advantage of the [CPU frequency scaling governor](https://wiki.archlinux.org/index.php/CPU_frequency_scaling#Scaling_governors). 

My CPU uses ``powersave`` as the default governor. Please check which is the default for your CPU by running the following command in the terminal: 
```
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
``` 

Update the ``cpu_mode_release.sh`` located in ``hooks/win11/release/end`` and replace ``powersave`` with your default governor. Also rename the ``win11`` folder to the the name of your VM and then run:
```
sudo ./setup_cpu_governor_hooks.sh
```

The file tree should look similar to this now:

```
$ tree /etc/libvirt/hooks/
/etc/libvirt/hooks/
├── qemu
└── {name of your VM}
	├── prepare
	│   └── begin
	│       ├── ...
	│       └── cpu_mode_performance.sh
	└── release
		└── end
			├── ...
			└── cpu_mode_release.sh
```
	
	
#### CPU passthrough mode
	
- This might not work as expected, as for me the latency improved but the L3 cache size changed from 32MB to 16MB, so I ended up not using this.
- To check the cache latency, use AIDA64 Memory & Cache benchmarks (Tools->Memory & Cache benchmarks).
- Also check your cache topology and size inside the VM using [Coreinfo](https://learn.microsoft.com/en-us/sysinternals/downloads/coreinfo)
- This does not necessarily improve your performance, so please benchmark before and after to see which is better.
- We can improve cache latency by changing from ``<cpu mode="host-passthrough">`` to a custom mode that better matches your CPU.
	1) To get a detailed info about your CPU, run ``virsh capabilities`` inside your terminal, look for ``<arch>x86_64</arch>`` and under that arch look for ``<model>``. This is the model we are going to use inside our VM setup.
	
		![virsh capabilities model](./images/virsh%20capabilities%20model.png)
	
	2) Go to VM settings, CPU, uncheck the ``Copy host CPU configuration`` and select the model you got from the previous step in the drop down menu.
	
		![CPU model select](./images/CPU%20model%20select.png)
	
	3) You will have to remove the ``<cache mode="passthrough"/>`` option from the ``<cpu>`` inside your XML for this to work. You can try ``<cache level="3" mode="emulate"/>`` and see if that improves the performance over having no ``cache`` option. For me, it didn't make a difference in latency benchmarks so I removed it, but that might not be the case for you, so benchmark it.
	
		![remove cache](./images/remove%20cache.png)


#### Line-Based vs. Message Signaled-Based Interrupts (MSI)
  
- This can sometimes help with audio stutters and cracks.
- TL/DR: With this you can switch from Line-Based to MSI for improved interrupts handling which should improve audio stutters and cracks and some potential VM crashes related to interrupts.
- Take a look at [this](https://forums.guru3d.com/threads/windows-line-based-vs-message-signaled-based-interrupts-msi-tool.378044/) detailed guide. I used MSI Utility V3 from the link in the post to switch to MSI


#### Internet improvements

- Follow [this](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Virtio_network) link to possibly improve internet performance.
- TL/DR: Set the network device as in the following picture. You will need the `NetKVM` driver for the ethernet controller inside the VM found in [virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/) file.

![Internet setup](./images/Internet%20setup.png)


### EAC games detecting VM

Some games that use EAC might detect that Windows is running inside a VM. To try and fix that, enter the following line inside the `<os>` section in your XML config file for the VM:
```
<smbios mode="host"/>
```


### Logging

* Check all hook logs with ```sudo cat /dev/kmsg | grep libvirt-qemu```

* Check all libvirt logs in ```/var/log/libvirt/libvirtd.log``` file

* Check all qemu logs in ```/var/log/libvirt/qemu/``` directory 
    

## Credits

- BigAnteater for easy guide and scripts for setting up GRUB, libvirt and qemu: https://github.com/BigAnteater/KVM-GPU-Passthrough
- RisingPrismTV for amazing hooks scripts: https://gitlab.com/risingprismtv/single-gpu-passthrough
- Zile995 for the really detailed guide: https://github.com/Zile995/PinnacleRidge-Polaris-GPU-Passthrough
- Bryansteiner for details on CPU pinning and governor: https://github.com/bryansteiner/gpu-passthrough-tutorial
