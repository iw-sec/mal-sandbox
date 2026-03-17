# mal-sandbox
my sandbox for analysis of Windows x86-64 malware

<br>

## Replication
### Defining Guest / Interfaces

> [!NOTE]
> The following is intended for libvirt-based virtualization (KVM/QEMU). If you use another VM manager or hypervisor (VMware, VirtualBox, etc.), you can still create a similar guest VM using the hardware configurations shown [below](https://github.com/isaacward1/my-mal-sandbox/blob/main/README.md#system).


These are the libvirt XML files for replicating my KVM/QEMU VM and networks:

- [mal-host-only.xml](mal-host-only.xml)
- [mal-NAT.xml](mal-NAT.xml)
- [mal-win10.xml](mal-win10.xml)
    
To create an identical guest VM: 

    sudo virsh net-define mal-host-only.xml
    sudo virsh net-define mal-NAT.xml
    sudo virsh nwfilter-define mal-isolate.xml
    sudo virsh nwfilter-define mal-root.xml
    sudo virsh define mal-win10.xml

> [!NOTE]
> replace  disk 'PATH_TO_DISK_IMAGE' in [mal-win10.xml](mal-win10.xml) with the path to a valid qcow2 image file (default: /var/lib/libvirt/images/\<disk name\>.qcow2)

### Installing VirtIO
1. Download the latest [virtio-win](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso) driver
2. Follow these [instructions](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers#Using_the_ISO)

> [!NOTE]
> if encountering heavy pixelation and screen tearing during/after boot, disable opengl/3d acceleration temporarily, install this driver, then reenable.

### Setup.ps1
This [script](setup.ps1) automates the configuration of several system/network settings and appearance/performance tweaks 
- `$hostonly_mac` and `$nat_mac` values should be changed reflect VM-side MAC address (determined with `virsh domiflist mal-win10`)
- Tools are installed via Chocolately packages, but can be installed manually via [links below](https://github.com/isaacward1/mal-sandbox/blob/main/README.md#analysis-tools)
- Things to change manually are listed at the bottom cuz powershell is trash

### Removing Interference
Though [disable-defender.exe](https://github.com/pgkt04/defender-control/releases/tag/v1.5) should be enough, if zero interference is desired, follow these [steps](https://github.com/mandiant/flare-vm?tab=readme-ov-file#pre-installation) to permanently disable Defender, Tamper Protection, and Windows Updates.

<br>

## System
- Windows 10
- 4 vCPUs (1 socket, 2 cores, 2 threads)
- 8 GB Memory
- 50 GB Storage
- Custom host-only network interface:
    - Name: mal-host-only
    - Mode: host-only or isolated
    - Subnet: 10.0.0.0/30
    - Disable DHCP and IPv6
- Custom NAT network interface:
    - Name: mal-NAT
    - Mode: NAT   
    - Subnet: 172.16.20.0/30
    - Disable DHCP and IPv6
- 3D acceleration

> [!CAUTION]
> Avoid using shared clipboard, shared folders (read + write), drag-and-drop, or USB storage passthrough/redirection. These are common vectors for VM escape.

> [!CAUTION]
> It is not recommended to allow internet access to the VM if you are not aware of the possible consequences. Use [FakeNet](https://github.com/mandiant/flare-fakenet-ng) or [INetSim](https://www.inetsim.org/index.html) and no NAT/bridge interface if unsure.

<br>

## Analysis Tools
### Static
- [PEStudio](https://www.winitor.com/download)
- [PE-bear](https://github.com/hasherezade/pe-bear)
- [DIE](https://github.com/horsicq/DIE-engine/releases)
- [dnSpyEx](https://github.com/dnSpyEx/dnSpy)
- [ImHex](https://github.com/WerWolv/ImHex)
- [Ghidra](https://github.com/NationalSecurityAgency/ghidra)
- [CyberChef](https://github.com/gchq/CyberChef)
- [FLOSS](https://github.com/mandiant/flare-floss)
- [CAPA](https://github.com/mandiant/capa/releases)
- [YARA](https://github.com/VirusTotal/yara)

### Dynamic
- [x64dbg](https://github.com/x64dbg/x64dbg)
- [PE-sieve](https://github.com/hasherezade/pe-sieve)
- [Wireshark](https://www.wireshark.org/download.html)
- [mitmproxy](https://www.mitmproxy.org/)
- [Sysinternals Suite](https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite)
- [System Informer](https://github.com/winsiderss/systeminformer)

### Other
- [disable-defender.exe](https://github.com/pgkt04/defender-control/releases/tag/v1.5)
- [VS Code](https://code.visualstudio.com/)
- [Python](https://www.python.org/downloads/) (v3.14)
- [Volatility 3](https://github.com/volatilityfoundation/volatility3)
- [Temurin JDK](https://adoptium.net/temurin/releases) (v21.0)
- [UniExtract2](https://github.com/Bioruebe/UniExtract2)
- [7-Zip](https://www.7-zip.org/)

<br>

## Network Isolation
Isolation is done mostly through libvirt [network filters](https://libvirt.org/formatnwfilter.html).

### mal-isolate:
    <filter name='mal-isolate' chain='ipv4' priority='-700'>
      <!-- allow outbound to mal-ho-br -->
      <rule action='accept' direction='out' priority='500'>
        <ip dstipaddr='10.0.0.1'/>
      </rule>
      
      <!-- allow outbound to mal-NAT-br -->
      <rule action='accept' direction='out' priority='500'>
        <ip dstipaddr='172.16.20.1'/>
      </rule>
     
      <!-- block outbound to LAN IPs-->
      <rule action='drop' direction='out' priority='501'>
        <ip dstipaddr='10.0.0.0' dstipmask='8'/>
      </rule>
      <rule action='drop' direction='out' priority='501'>
        <ip dstipaddr='172.16.0.0' dstipmask='12'/>
      </rule>
      <rule action='drop' direction='out' priority='501'>
        <ip dstipaddr='192.168.0.0' dstipmask='16'/>
      </rule>
    
      <!-- allow outbound to anywhere else -->
      <rule action='accept' direction='out' priority='600'/>
    </filter>

### mal-root:
    <filter name='mal-root' chain='root'>
      <filterref filter='allow-arp'/>
      <filterref filter='clean-traffic'/>
      <filterref filter='mal-inet-only'/>
    </filter>

### UFW
Firewall rule applied on the host. It allows inbound access from the VM to the host's python http server.
    
    iface="mal-ho-br"	# name of VM's host-only bridge
    br_ip="10.0.0.1"	# host-only interface's gateway IP
    vm_ip="10.0.0.2"	# host IP assigned to VM on host-only network
    port="8888"			# python http.server port
    
    sudo ufw allow in on $iface from $vm_ip to $br_ip port $port proto tcp comment '(mal) allow to host python http.server'

<br>

## File Transfer

### Using Python [http.server](https://docs.python.org/3/library/http.server.html#)

#### Uploading from Host --> VM

1. Run on host to serve malware to VM:
 
        python3 -m http.server -d /path/to/served/dir --bind <host-only-gateway> <python server port>

3. On VM's browser, navigate to `http://<host-only-gateway>:<python server port>`

#### Downloading from VM --> Host

1. Run on VM to download files to host:

        python3 -m http.server --bind <vm-hostonly-ip> <python server port>

2. On host's browser, navigate to `http://<vm-hostonly-ip>:<python server port>`

### Alternatives
- Hardened scp/OpenSSH
- Dedicated lightweight VM or container for uploading and downloading files to/from VM
- Read-only shared folder
- Downloading malware onto VM from online DBs (temporary internet)

<br>

## Tips
- After setup and tweaking, take a snapshot to revert back to a clean state after detonating malware.
- Before executing malware, ensure all hypervisor/emulation software is up to date with the latest security patches applied.
- Use bash alias for python server<br>
  Ex: `alias pyserver='python3 -m http.server -d ~/Downloads/mal-win10 --bind 10.0.0.1 8888'`
- Ignore everything above. Just use [FLARE-VM](https://github.com/mandiant/flare-vm) or [REMnux](https://remnux.org/).

<br>

<!-- 
To-Do
--------------------------------------
- Malcat
- Scylla
- IDA Free
- Binary Ninja
- Visual Studio

- right-click context menu for tools
- turn off cloud-based protection and automatic sample submission via registry
-->
