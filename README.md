# ⚡ windows-deployment

> Automated Windows Server 2025 deployment on Proxmox VE — clone VMs, configure IPs, install roles, manage infrastructure — all from one web UI.

---

## 🚀 Quick start

```bash
git clone https://github.com/santiagotoro2023/windows-deployment
cd windows-deployment
sudo bash setup.sh
```

Opens at **`http://<server-ip>:3000`**

```bash
# Uninstall
sudo bash setup.sh uninstall
```

---

## 📋 Requirements

| | |
|---|---|
| **Proxmox VE** | 8.x |
| **Deployment host** | Debian 11/12 or Ubuntu 22.04/24.04 (any Linux VM in the same network) |
| **Windows template** | Built once — see below |

---

## 🖼️ Building the Windows Server 2025 template

> **Do this once.** All deployed VMs are full clones of this template. Getting Cloudbase-Init right here is the key to everything working automatically.

### What you need
- A Windows Server 2025 ISO (evaluation version is fine — 180 days free)
- The VirtIO drivers ISO (from the Fedora project)
- Both uploaded to your Proxmox ISO storage

### VM setup pointers
- Use machine type **q35**, firmware **OVMF (UEFI)**
- Add a **VirtIO SCSI** disk (60 GB is enough for a template)
- Attach both ISOs as CDROMs
- Add a **Cloud-Init drive** (IDE) — this is what carries IP/password/hostname to the VM
- Enable the QEMU Guest Agent

### Windows installation
- Choose **Standard (Desktop Experience)** during setup
- Load the VirtIO storage driver when prompted (`vioscsi\w11\amd64` on the driver ISO)

### After installation — key steps

1. **Install the VirtIO Guest Agent** from the driver ISO
2. **Pre-configure WinRM** so Ansible can connect after deployment:
   ```powershell
   winrm quickconfig -q
   winrm set winrm/config/service '@{AllowUnencrypted="true"}'
   winrm set winrm/config/service/auth '@{Basic="true"}'
   netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   ```
3. **Install Windows Updates** (reboot as needed)
4. **Install Cloudbase-Init** — the Windows equivalent of cloud-init. Download the latest MSI from the [Cloudbase-Init releases page](https://github.com/cloudbase/cloudbase-init/releases).

### Cloudbase-Init configuration

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

### Unattend.xml — skip the OOBE setup wizard

Create `C:\Windows\System32\Sysprep\unattend.xml` — without this, Windows will show the "Hello" setup wizard on every first boot instead of letting Cloudbase-Init take over:

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

### Sysprep and convert to template

```powershell
Clear-EventLog -LogName Application, Security, System
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown `
  /unattend:C:\Windows\System32\Sysprep\unattend.xml
```

Then on the Proxmox host, convert the VM to a template:
```bash
qm template <vmid>
```

> ⚠️ Windows allows a maximum of **8 Sysprep runs** per installation. After that you need to rebuild from scratch.

---

## 🔐 Users & access

Users are managed entirely within the application — no Linux system accounts needed.

### Roles

| Role | What they can do |
|---|---|
| 🔴 `admin` | Everything — users, organisations, hosts, settings, templates, deploy |
| 🟡 `deploy` | Add/edit VMs, run deploys, manage own templates |
| 🔵 `readonly` | View VMs, hosts and logs — no changes |

### First login

On first startup a default admin account is created:

| Username | Password |
|---|---|
| `admin` | `admin` |

**Change this immediately** in **Admin → Users**.

### Managing users

Go to **Admin → Users** to create, edit and delete users directly in the UI. No terminal access required.

---

## 🏢 Organisations

Group Proxmox nodes by customer, location or environment. The sidebar shows a 3-level tree:

```
🏢 Customer A
   ├── 🖥 pve-zurich-01   2/3 VMs running
   └── 🖥 pve-zurich-02   0/1 VMs running
🏢 Customer B
   └── 🖥 pve-berlin-01   2/2 VMs running
    Unassigned
   └── 🖥 pve-dev-01
```

Each organisation has its own **defaults** (gateway, VLAN, storage, bridge, template name, DNS) that override global settings for all hosts inside. These can still be overridden per-host or per-VM.

Click **🏢** in the sidebar or go to **Admin → Organisations** to create one.

---

## ⚙️ Settings

Before deploying, configure the network defaults under **Settings**:

- Network prefix, gateway, subnet mask
- Default VLAN (e.g. `10`)
- Primary and secondary DNS
- Windows Administrator password
- Timezone and locale

These are the global defaults — organisations, hosts and individual VMs can override them.

---

## 🚀 Deploying VMs

### Setup checklist
1. ✅ Template VM built and converted in Proxmox
2. ✅ Proxmox API token created with `PVEAdmin` role
3. ✅ Network settings configured in **Settings**
4. ✅ Organisation created (optional)
5. ✅ Host added via **+ Add Host**
6. ✅ VMs added via **+** in the sidebar

Then go to **Deploy → ⚡ Deploy All**. The log streams live. Click **✕ Abort** at any time — all VMs created during this run are deleted automatically from Proxmox.

### API token for Proxmox

```bash
pveum user token add root@pam deployment-token --privsep=0
pveum acl modify / --token 'root@pam!deployment-token' --role PVEAdmin
```

### VM roles

| # | Role | Windows Features |
|---|---|---|
| 1 | 🛡 Domain Controller | AD-Domain-Services, DNS, DHCP, GPMC, RSAT-AD-Tools |
| 2 | 📁 File Server | FS-FileServer, FS-DFS-Namespace, FS-DFS-Replication |
| 3 | 💾 Backup Server | Base config only — install backup software manually |
| 4 | 🔀 RDS Broker | RDS-Connection-Broker, RDS-Licensing, RDS-Web-Access |
| 5 | 🖥 RDS Session Host | RDS-RD-Server, Desktop-Experience |
| 6 | 🖨 Print Server | Print-Server, RSAT-Print-Services |
| 7 | ⚙️ Management | Full RSAT suite + GPMC |

Every VM gets: hostname, static IP, timezone, DNS servers, RDP enabled.

---

## 💾 Deployment templates

Save a full VM configuration as a reusable template and share it across your team.

| | Global template | Personal template |
|---|---|---|
| Created by | admin | deploy or admin |
| Visible to | everyone | owner only |
| Export/Import | ✅ JSON | ✅ JSON |

**Save:** Deploy view → 💾 **Save as Template**  
**Apply:** Templates tab → ⚡ **Use**  
**Share:** Export JSON → send file → Import on another instance

---

## 🖱️ VM management

Click any VM to open the detail panel:

| | |
|---|---|
| ▶ Start / ■ Stop | Power control via Proxmox API |
| ↺ Reboot / ⏻ Shutdown | Graceful restart or shutdown |
| 🖥 Open Console | Direct link to Proxmox KVM console |
| ⬇ Download .rdp | Ready-to-use RDP file for Windows Remote Desktop |

---

## 🗄️ Data storage

Everything is stored server-side — reloading the page, switching browsers or using multiple accounts all show the same state.

| File | Contents |
|---|---|
| `data/config.json` | Hosts, VMs, global settings |
| `data/organisations.json` | Organisations and their defaults |
| `data/users.json` | User accounts and roles |
| `data/templates.json` | Deployment templates |
| `data/deploy_state.json` | Current / last deploy log |
| `data/deploy_history.json` | Last 50 deploy runs |

---

## 🔧 Troubleshooting

**Cloud-Init not applied (wrong IP or hostname after boot)**  
Check `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init.log` on the VM. Most common cause: gateway is not in the same subnet as the VM IP, or Cloudbase-Init was not installed before Sysprep.

**WinRM connection refused**  
Allow 5–10 minutes after first boot — Cloudbase-Init needs to finish configuring WinRM. Verify WinRM was pre-configured in the template (step 4 above).

**Credentials rejected by Ansible**  
The password in **Settings → Windows Administrator Password** must match the one configured in the template. Default is `Asdf1234!`.

**Template not found**  
The Template VM Name must exactly match the Proxmox VM name (case-sensitive).

**RDP not working**  
Run on the VM: `Enable-NetFirewallRule -DisplayName 'Remote Desktop*'`

---

## 📁 Files

```
setup.sh    — single-file installer and complete application
README.md   — this file
```
