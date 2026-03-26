# windows-deployment

Automated Windows Server 2025 deployment on Proxmox VE.  
Clone VMs, set static IPs, enable RDP, install Windows role features.

## Install

```bash
wget https://raw.githubusercontent.com/santiagotoro2023/windows-deployment
cd windows-deployment
sudo bash setup.sh
```

Opens at `http://<server-ip>:3000`

## Uninstall

```bash
sudo bash setup.sh uninstall
```

## Roles

| Role | Windows Features installed |
|---|---|
| **Domain Controller** | AD-Domain-Services, DNS, DHCP, GPMC (Group Policy), RSAT-AD-Tools |
| **File Server** | FS-FileServer, FS-DFS-Namespace, FS-DFS-Replication, FS-Resource-Manager |
| **Backup Server** | *(blank — install backup software manually)* |
| **RDS Broker** | RDS-Connection-Broker, RDS-Licensing, RDS-Web-Access |
| **RDS Session Host** | RDS-RD-Server, Desktop-Experience |
| **Print Server** | Print-Server, Spooler |
| **Management** | Full RSAT suite + GPMC |

Every VM gets: hostname, timezone, DNS servers, **RDP enabled**.

## Requirements

- Debian 11/12 or Ubuntu 22.04/24.04
- Proxmox VE 8.x with API token
- Windows Server 2025 template on Proxmox → [TEMPLATE.md](TEMPLATE.md)

## Files

```
setup.sh      ← installer + full app (everything in one file)
README.md     ← this file
TEMPLATE.md   ← how to build the Windows Server 2025 Proxmox template
```
