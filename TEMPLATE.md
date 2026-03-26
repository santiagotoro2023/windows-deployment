# Windows Server 2025 Template erstellen (Proxmox)

Dies ist der **wichtigste Schritt** – alle VMs werden von diesem Template geklont.

---

## Schritt 1 — ISO herunterladen

```bash
# Auf dem Proxmox Host:
cd /var/lib/vz/template/iso/

# Windows Server 2025 Evaluation (180 Tage, kostenlos)
wget "https://go.microsoft.com/fwlink/?linkid=2293312" \
  -O WinServer2025.iso

# VirtIO-Treiber ISO (zwingend erforderlich!)
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## Schritt 2 — VM erstellen (Proxmox UI oder CLI)

```bash
# VM erstellen (ID 9000 = Template-Konvention)
qm create 9000 \
  --name "win2025-template" \
  --memory 4096 \
  --cores 2 \
  --cpu host \
  --machine q35 \
  --bios ovmf \
  --efidisk0 local-lvm:0,efitype=4m,pre-enrolkeys=1 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:60,cache=writeback,discard=on \
  --ide2 local:iso/WinServer2025.iso,media=cdrom \
  --ide3 local:iso/virtio-win.iso,media=cdrom \
  --net0 virtio,bridge=vmbr0 \
  --ostype win11 \
  --tablet 0 \
  --agent enabled=1 \
  --vga qxl \
  --serial0 socket \
  --boot order=ide2
```

---

## Schritt 3 — Windows installieren

1. VM starten, via Proxmox Console verbinden
2. Windows Server 2025 **Standard (Desktop Experience)** wählen
3. Bei Treibern: **Load driver** → VirtIO-CD → `vioscsi\w11\amd64`
4. Installation durchführen (Passwort für Administrator setzen)

---

## Schritt 4 — Post-Install in Windows (PowerShell als Admin)

```powershell
# VirtIO Guest Agent installieren (von D:\ = virtio-win.iso)
Start-Process "D:\virtio-win-gt-x64.msi" -ArgumentList "/qn" -Wait

# WinRM für Ansible aktivieren
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
Set-Item WSMan:\localhost\Service\Auth\Kerberos -Value $true
netsh advfirewall firewall add rule name="WinRM HTTP" `
  dir=in action=allow protocol=TCP localport=5985

# Firewall für spätere Ansible-Kommunikation
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
# (Später via GPO präzise konfigurieren)

# Windows Updates installieren
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

# Cloudbase-Init installieren (Cloud-Init für Windows)
# Download: https://cloudbase.it/cloudbase-init/
$url = "https://github.com/cloudbase/cloudbase-init/releases/latest/download/CloudbaseInitSetup_x64.msi"
Invoke-WebRequest $url -OutFile "C:\CloudbaseInit.msi"
Start-Process msiexec -ArgumentList "/i C:\CloudbaseInit.msi /qn" -Wait
```

---

## Schritt 5 — Cloudbase-Init konfigurieren

Datei: `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf`

```ini
[DEFAULT]
username=Administrator
groups=Administrators
inject_user_password=true
config_drive_raw_hhd=true
config_drive_cdrom=true
first_logon_behaviour=no
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService
plugins=cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,
        cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin,
        cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin,
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin
allow_reboot=true
stop_service_on_exit=false
```

---

## Schritt 6 — Sysprep + Template konvertieren

```powershell
# In Windows (letzte Aktion vor Sysprep):
# Alle temporären Dateien löschen
Remove-Item C:\CloudbaseInit.msi -Force
Clear-EventLog -LogName Application, Security, System

# Sysprep ausführen (VM wird danach automatisch herunterfahren)
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown
```

```bash
# Auf Proxmox Host – VM in Template konvertieren:
qm template 9000
```

✅ Template ist fertig! VM ID 9000 erscheint jetzt als Template in der Proxmox UI.

---

## Wichtige Hinweise

| Thema | Detail |
|---|---|
| Sysprep Limit | Windows erlaubt max. 8x Sysprep auf derselben Installation |
| EFI/UEFI | Template nutzt OVMF – alle geklonten VMs erben dies |
| VirtIO Treiber | Zwingend für Network + Disk Performance |
| Cloudbase-Init | Ersetzt cloud-init für Windows – injiziert Hostname + IP via Proxmox |
| WinRM | Muss vor Template-Konvertierung aktiv sein |
