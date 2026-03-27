# windows-deployment

Automated Windows Server 2025 deployment on Proxmox VE — with a full management web UI.

Clone VMs, configure static IPs, enable RDP, install Windows roles, manage multiple Proxmox environments organised by customer or location — all from one place.

---

## Quick start

```bash
git clone https://github.com/santiagotoro2023/windows-deployment
cd windows-deployment
sudo bash setup.sh
```

Opens at `http://<server-ip>:3000`

**Uninstall:**
```bash
sudo bash setup.sh uninstall
```

---

## Requirements

| Component | Notes |
|---|---|
| Proxmox VE | 8.x |
| Deployment host OS | Debian 11/12 or Ubuntu 22.04/24.04 |
| Windows Server template | Built from scratch — see below |

The deployment host can be any Linux VM — it does not need to run on the Proxmox host itself.

---

## Building the Windows Server 2025 template

> This is the most important step. Every VM is cloned from this template. If Cloudbase-Init is not set up correctly here, Cloud-Init settings will not apply after deployment.

### 1 — Download ISOs on the Proxmox host

```bash
cd /var/lib/vz/template/iso/

# Windows Server 2025 Evaluation (180 days, free)
wget "https://go.microsoft.com/fwlink/?linkid=2293312" -O WinServer2025.iso

# VirtIO drivers — required for disk and network
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

### 2 — Create the VM

```bash
qm create 9000 \
  --name "win2025-template" \
  --memory 4096 --cores 2 --cpu host \
  --machine q35 --bios ovmf \
  --efidisk0 local-lvm:0,efitype=4m,pre-enrolkeys=1 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:60,cache=writeback,discard=on \
  --ide2 local:iso/WinServer2025.iso,media=cdrom \
  --ide3 local:iso/virtio-win.iso,media=cdrom \
  --net0 virtio,bridge=vmbr0 \
  --ostype win11 --tablet 0 \
  --agent enabled=1 --vga qxl --serial0 socket \
  --boot order=ide2

# Add Cloud-Init drive — required for IP/password/hostname injection
qm set 9000 --ide1 local-lvm:cloudinit
```

### 3 — Install Windows

1. Start the VM, open the Proxmox console
2. Choose **Windows Server 2025 Standard (Desktop Experience)**
3. When prompted for drivers: **Load driver** → VirtIO CD → `vioscsi\w11\amd64`
4. Complete installation and set an Administrator password

### 4 — Post-install configuration (PowerShell as Administrator)

```powershell
# VirtIO Guest Agent (from D:\ = virtio-win ISO)
Start-Process "D:\virtio-win-gt-x64.msi" -ArgumentList "/qn" -Wait

# Pre-configure WinRM so Ansible can connect after deployment
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM HTTP" `
  dir=in action=allow protocol=TCP localport=5985

# Disable firewall (configure properly via GPO later)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Install Windows Updates
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

# Install Cloudbase-Init
$url = "https://github.com/cloudbase/cloudbase-init/releases/latest/download/CloudbaseInitSetup_x64.msi"
Invoke-WebRequest $url -OutFile "C:\CloudbaseInit.msi"
Start-Process msiexec -ArgumentList "/i C:\CloudbaseInit.msi /qn" -Wait
```

### 5 — Configure Cloudbase-Init

Edit `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf`:

```ini
[DEFAULT]
username=Administrator
groups=Administrators
inject_user_password=true
config_drive_raw_hhd=true
config_drive_cdrom=true
config_drive_vfat=true
first_logon_behaviour=no
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService
plugins=cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,
        cloudbaseinit.plugins.windows.createuser.CreateUserPlugin,
        cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin,
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,
        cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin,
        cloudbaseinit.plugins.windows.winrmlistener.ConfigWinRMListenerPlugin,
        cloudbaseinit.plugins.windows.winrmcertificateauth.ConfigWinRMCertificateAuthPlugin
allow_reboot=true
stop_service_on_exit=false
```

### 6 — Unattend.xml (skip OOBE on first boot)

Create `C:\Windows\System32\Sysprep\unattend.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
    </component>
  </settings>
</unattend>
```

### 7 — Sysprep and convert to template

```powershell
# Clean up
Remove-Item C:\CloudbaseInit.msi -Force -ErrorAction SilentlyContinue
Clear-EventLog -LogName Application, Security, System

# Sysprep — VM shuts down automatically
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown `
  /unattend:C:\Windows\System32\Sysprep\unattend.xml
```

Then on the Proxmox host:

```bash
qm template 9000
```

> Windows allows a maximum of 8 Sysprep runs per installation. If you reach this limit, rebuild the template from scratch.

---

## Authentication

The tool uses **Linux PAM** — users sign in with their system credentials. No separate password database needed.

### Roles

| Role | Permissions |
|---|---|
| `admin` | Full access — users, organisations, hosts, settings, templates, deploy |
| `deploy` | Add/edit VMs, run deploys, manage own templates |
| `readonly` | View everything — no changes |

### Adding users

The user must exist as a Linux system user:

```bash
useradd -m -s /bin/bash alice
passwd alice
```

Then add them in **Admin → Users → + Add User** and assign a role.

The Linux user `root` gets `admin` role automatically on first startup.

---

## Organisations

Group Proxmox nodes logically — by customer, location or environment.

```
🏢 Customer A
   ├── pve-zurich-01   (3 VMs running)
   └── pve-zurich-02   (1 VM stopped)
🏢 Customer B
   └── pve-berlin-01   (2 VMs running)
Unassigned
   └── pve-dev-01
```

Each organisation has its own **defaults** that override global settings for all hosts inside it:

- Gateway, VLAN, storage pool, network bridge
- Template VM name, DNS servers

Defaults can still be overridden per-host and per-VM.

**Create an organisation:** click the 🏢 button in the sidebar, or go to **Admin → Organisations**.

---

## Deploying VMs

### 1 — Configure global defaults

**Settings** → set gateway, subnet, VLAN, DNS, Administrator password, timezone.

### 2 — Add a Proxmox host

Click **+ Add Host**. You need a Proxmox API token with admin rights:

```bash
pveum user token add root@pam deployment-token --privsep=0
pveum acl modify / --token 'root@pam!deployment-token' --role PVEAdmin
```

Enter the **Template VM Name** exactly as it appears in Proxmox (e.g. `win2025-template`), assign an organisation if applicable.

### 3 — Add VMs

Click **+** in the sidebar. Set hostname, IP, role — and optionally VLAN and bridge per VM to override the defaults.

### 4 — Deploy

**Deploy → ⚡ Deploy All**. The log streams live. Click **✕ Abort** at any time — all VMs created during this run are deleted automatically.

### VM roles

| # | Role | Windows Features installed |
|---|---|---|
| 1 | Domain Controller | AD-Domain-Services, DNS, DHCP, GPMC, RSAT-AD-Tools |
| 2 | File Server | FS-FileServer, FS-DFS-Namespace, FS-DFS-Replication, FS-Resource-Manager |
| 3 | Backup Server | Base config only — install backup software manually |
| 4 | RDS Broker | RDS-Connection-Broker, RDS-Licensing, RDS-Web-Access |
| 5 | RDS Session Host | RDS-RD-Server, Desktop-Experience |
| 6 | Print Server | Print-Server, RSAT-Print-Services |
| 7 | Management | Full RSAT suite + GPMC |

Every VM gets: hostname, static IP, timezone, DNS servers, RDP enabled.

---

## Deployment templates

Save a full VM configuration as a reusable template.

| Template type | Who can see it |
|---|---|
| Global (admin) | All users |
| Personal (deploy role) | Owner only |

**Save current config:** Deploy view → 💾 Save as Template  
**Apply a template:** Templates tab → ⚡ Use  
**Share:** Export as JSON → send file → Import on another instance

---

## VM management

Click any VM in the sidebar or grid to open the detail panel:

| Action | |
|---|---|
| ▶ Start / ■ Stop | Power control via Proxmox API |
| ↺ Reboot / ⏻ Shutdown | Graceful or forced |
| 🖥 Open Console | Direct link to Proxmox KVM console |
| ⬇ Download .rdp | Ready-to-use RDP file for Windows Remote Desktop |

---

## Data storage

Everything is stored server-side — page reloads, multiple users and different browsers all see the same state.

| File | Contents |
|---|---|
| `data/config.json` | Hosts, VMs, global settings |
| `data/organisations.json` | Organisations and their defaults |
| `data/users.json` | User → role mappings |
| `data/templates.json` | Deployment templates |
| `data/deploy_state.json` | Current / last deploy log |
| `data/deploy_history.json` | Last 50 deploy runs |

---

## Troubleshooting

**Cloud-Init not applied (wrong IP / hostname after boot)**  
Check `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init.log`. Most common cause: gateway is not in the same subnet as the VM IP, or Cloudbase-Init was not installed before Sysprep.

**WinRM connection refused**  
Allow 5–10 minutes after first boot — Cloudbase-Init needs to finish. Verify WinRM was pre-configured in the template (step 4).

**Credentials rejected by Ansible**  
The password in **Settings → Windows Administrator Password** must match what Cloudbase-Init sets. Default is `Asdf1234!`.

**Template not found**  
The Template VM Name must exactly match the Proxmox VM name (case-sensitive). Check under the node in the Proxmox UI.

**RDP not enabled**  
Run on the VM: `Enable-NetFirewallRule -DisplayName 'Remote Desktop*'`

---

## Files

```
setup.sh    — single-file installer + complete application
README.md   — this file
```
