#!/usr/bin/env bash
# =============================================================================
#  windows-deployment — single-file installer
#  Usage: sudo bash setup.sh [install|uninstall|status]
# =============================================================================
set -euo pipefail

APP="windows-deployment"
DIR="/opt/${APP}"
SVC="/etc/systemd/system/${APP}.service"
LOG="/var/log/${APP}.log"
PORT="${PORT:-3000}"

RED='\033[0;31m';GREEN='\033[0;32m';YEL='\033[1;33m'
BLU='\033[0;34m';CYN='\033[0;36m';BOLD='\033[1m';NC='\033[0m'
ok()  { echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG"; }
inf() { echo -e "${BLU}[i]${NC} $*" | tee -a "$LOG"; }
err() { echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG"; exit 1; }
sec() { echo -e "\n${BOLD}${CYN}── $* ──${NC}\n" | tee -a "$LOG"; }
banner() {
  echo -e "${BOLD}${CYN}"
  echo "  ┌──────────────────────────────────────────┐"
  echo "  │        windows-deployment                │"
  echo "  │   Proxmox + Ansible + Windows Server     │"
  echo "  └──────────────────────────────────────────┘"
  echo -e "${NC}"
}
check_root() { [[ $EUID -eq 0 ]] || err "Run as root: sudo bash setup.sh"; }

write_files() {
  inf "Writing files to ${DIR}…"
  mkdir -p "${DIR}"/{frontend,backend/data,ansible/{roles/{common,dc,fileserver,backupserver,rds_broker,rds_sessionhost,printserver,mgmt,proxmox_provision,ad_setup}/tasks,group_vars,inventory},docs}

  # ---------------------------------------------------------------------------
  # frontend/index.html
  # ---------------------------------------------------------------------------
  cat > "${DIR}/frontend/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Windows Deployment</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#0c0f16;--panel:#111826;--panel2:#16202f;--panel3:#1c2840;
  --b1:#1e2d42;--b2:#263855;--b3:#2f4566;
  --amber:#e8a020;--amber-d:rgba(232,160,32,.08);--amber-b:rgba(232,160,32,.22);
  --green:#3ecf5d;--green-d:rgba(62,207,93,.10);
  --red:#f05050;--red-d:rgba(240,80,80,.10);
  --blue:#5b9cf6;--blue-d:rgba(91,156,246,.10);
  --purple:#a78bfa;--purple-d:rgba(167,139,250,.08);
  --purple:#a78bfa;--purple-d:rgba(167,139,250,.10);
  --text:#d4dff0;--text2:#7a91ae;--text3:#3d5470;
  --mono:'DM Mono',monospace;--sans:'DM Sans',sans-serif;
  --rad:3px;--rad2:5px;
}
html,body{height:100%;overflow:hidden}
body{background:var(--bg);color:var(--text);font-family:var(--sans);font-size:13px;display:flex;flex-direction:column}

/* ── Login Screen ── */
#login-screen{position:fixed;inset:0;background:var(--bg);display:flex;align-items:center;justify-content:center;z-index:200}
.login-box{background:var(--panel);border:1px solid var(--b2);border-radius:var(--rad2);padding:32px;width:340px;box-shadow:0 20px 60px rgba(0,0,0,.7)}
.login-logo{display:flex;align-items:center;gap:10px;margin-bottom:24px}
.login-logo-mark{width:32px;height:32px;background:var(--amber);border-radius:var(--rad);display:flex;align-items:center;justify-content:center}
.login-logo-mark svg{width:17px;height:17px;fill:#000}
.login-logo-name{font-family:var(--mono);font-size:15px;font-weight:500}
.login-title{font-size:16px;font-weight:600;margin-bottom:6px}
.login-sub{font-size:12px;color:var(--text2);margin-bottom:20px}
.login-err{font-size:12px;color:var(--red);margin-bottom:12px;display:none}
.login-err.show{display:block}

#topbar{height:44px;background:var(--panel);border-bottom:1px solid var(--b1);display:flex;align-items:center;padding:0 14px;gap:10px;flex-shrink:0;z-index:20}
#brand{display:flex;align-items:center;gap:7px;margin-right:4px}
#brand-mark{width:24px;height:24px;background:var(--amber);border-radius:var(--rad);display:flex;align-items:center;justify-content:center}
#brand-mark svg{width:13px;height:13px;fill:#000}
#brand-name{font-family:var(--mono);font-size:12.5px;font-weight:500;letter-spacing:.01em;white-space:nowrap}
#topbar-div{width:1px;height:16px;background:var(--b2)}
#topnav{display:flex;gap:1px}
.tnb{background:transparent;border:1px solid transparent;color:var(--text2);padding:3px 11px;border-radius:var(--rad);cursor:pointer;font-family:var(--sans);font-size:12px;transition:all .12s;white-space:nowrap}
.tnb:hover{color:var(--text);background:var(--panel2)}.tnb.act{color:var(--amber);background:var(--amber-d);border-color:var(--amber-b)}
#topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px}
.conn-pill{display:flex;align-items:center;gap:5px;font-size:11px;color:var(--text2);font-family:var(--mono);background:var(--panel2);border:1px solid var(--b1);padding:2px 9px;border-radius:20px}
.cdot{width:5px;height:5px;border-radius:50%;flex-shrink:0;transition:background .3s}
.cdot.on{background:var(--green)}.cdot.off{background:var(--text3)}
.user-pill{display:flex;align-items:center;gap:6px;font-size:11px;color:var(--text2);font-family:var(--mono);background:var(--panel2);border:1px solid var(--b1);padding:2px 9px;border-radius:20px;cursor:pointer}
.user-pill:hover{border-color:var(--b2)}
.role-badge{padding:1px 6px;border-radius:var(--rad);font-size:9px;font-weight:600;text-transform:uppercase;letter-spacing:.05em}
.role-admin{background:rgba(167,139,250,.15);color:var(--purple)}
.role-deploy{background:rgba(62,207,93,.12);color:var(--green)}
.role-readonly{background:rgba(91,156,246,.12);color:var(--blue)}

#layout{display:flex;flex:1;overflow:hidden}
#sidebar{width:256px;flex-shrink:0;background:var(--panel);border-right:1px solid var(--b1);display:flex;flex-direction:column;overflow:hidden}
#sb-top{padding:8px;border-bottom:1px solid var(--b1);display:flex;gap:5px;align-items:center}
.sb-search{position:relative;flex:1}
.sb-search svg{position:absolute;left:7px;top:50%;transform:translateY(-50%);width:11px;height:11px;color:var(--text3);pointer-events:none}
#sb-input{width:100%;background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:5px 7px 5px 24px;border-radius:var(--rad);font-size:11.5px;font-family:var(--sans);outline:none;transition:border-color .12s}
#sb-input:focus{border-color:var(--amber)}#sb-input::placeholder{color:var(--text3)}
.sb-plus{width:26px;height:26px;background:var(--amber);color:#000;border:none;border-radius:var(--rad);cursor:pointer;font-size:17px;font-weight:700;line-height:1;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:opacity .12s}
.sb-plus:hover{opacity:.85}
.sb-icon{width:26px;height:26px;border:1px solid;border-radius:var(--rad);cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:all .12s;background:transparent}
.sb-icon:hover{filter:brightness(1.15)}
#tree{flex:1;overflow-y:auto;padding:3px 0 8px;user-select:none}
#tree::-webkit-scrollbar{width:3px}#tree::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}
/* Org + host tree */
.tr-org{margin-bottom:2px}
.tr-org-row{display:flex;align-items:center;gap:5px;padding:4px 8px;cursor:pointer;border-radius:var(--rad);margin:0 3px;transition:background .1s;border-bottom:1px solid var(--b1)}
.tr-org-row:hover{background:var(--panel2)}.tr-org-row.sel{background:var(--purple-d);outline:1px solid rgba(167,139,250,.3)}
.tr-org-name{font-size:11px;font-weight:600;flex:1;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;color:var(--text2);text-transform:uppercase;letter-spacing:.05em}
.tr-org-kids{margin:2px 3px 4px 10px;border-left:1px solid rgba(167,139,250,.2);padding-left:3px}
.tr-host{margin-bottom:1px}
.tr-host-row{display:flex;align-items:center;gap:5px;padding:5px 8px;cursor:pointer;border-radius:var(--rad);margin:0 3px;transition:background .1s}
.tr-host-row:hover{background:var(--panel2)}.tr-host-row.sel{background:var(--amber-d);outline:1px solid var(--amber-b)}
.tr-chv{width:12px;height:12px;flex-shrink:0;transition:transform .15s;color:var(--text3)}.tr-chv.open{transform:rotate(90deg)}
.tr-host-ic{width:17px;height:17px;border-radius:var(--rad);background:rgba(232,160,32,.12);border:1px solid rgba(232,160,32,.2);display:flex;align-items:center;justify-content:center;flex-shrink:0}
.tr-host-name{font-size:12px;font-weight:500;flex:1;overflow:hidden;white-space:nowrap;text-overflow:ellipsis}
.tr-cnt{font-size:10px;padding:0 5px;border-radius:8px;font-family:var(--mono)}
.tr-kids{margin:1px 3px 1px 16px;border-left:1px solid var(--b1);padding-left:3px}
.tr-vm{display:flex;align-items:center;gap:5px;padding:4px 7px;cursor:pointer;border-radius:var(--rad);margin:1px 0;transition:background .1s}
.tr-vm:hover{background:var(--panel2)}.tr-vm.sel{background:var(--amber-d)}.tr-vm.sel .tr-vm-name{color:var(--amber)}
.tr-dot{width:5px;height:5px;border-radius:50%;flex-shrink:0}
.dot-run{background:var(--green)}.dot-stop{background:var(--red)}.dot-pend{background:var(--text3)}
.dot-clone{background:var(--amber);animation:blink .8s infinite}.dot-conf{background:var(--blue);animation:blink .8s infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:.2}}
.tr-vm-ic{font-size:11px;flex-shrink:0;width:14px;text-align:center}
.tr-vm-name{font-size:11.5px;flex:1;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;font-family:var(--mono)}
.tr-vm-ip{font-size:10px;color:var(--text3);white-space:nowrap;flex-shrink:0}
.tr-empty{padding:5px 10px;font-size:11px;color:var(--text3);font-style:italic}

#content{flex:1;display:flex;overflow:hidden}
#main{flex:1;overflow-y:auto;background:var(--bg)}
#main::-webkit-scrollbar{width:4px}#main::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}
.view{display:none;padding:22px 24px;animation:fi .15s ease}.view.active{display:block}
@keyframes fi{from{opacity:0;transform:translateY(3px)}to{opacity:1;transform:none}}

.ph{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:18px}
.ph-l .ph-title{font-size:17px;font-weight:600;letter-spacing:-.02em}
.ph-l .ph-sub{font-size:11.5px;color:var(--text2);margin-top:2px}
.ph-r{display:flex;gap:6px;align-items:center;flex-shrink:0}

.stat-row{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-bottom:18px}
.stat-card{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);padding:12px 14px}
.stat-v{font-size:21px;font-weight:600;font-family:var(--mono);line-height:1}
.stat-l{font-size:9.5px;color:var(--text2);margin-top:4px;text-transform:uppercase;letter-spacing:.07em;font-weight:500}

.grid-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:9px}
.grid-label{font-size:10px;font-weight:600;color:var(--text3);text-transform:uppercase;letter-spacing:.08em}
.filter-row{display:flex;gap:3px}
.flt{background:transparent;border:1px solid var(--b1);color:var(--text2);padding:2px 9px;border-radius:20px;cursor:pointer;font-size:11px;transition:all .1s}
.flt:hover{border-color:var(--b2);color:var(--text)}.flt.act{background:var(--amber-d);border-color:var(--amber-b);color:var(--amber)}
.vm-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:7px}
.vm-card{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);padding:11px;cursor:pointer;transition:border-color .1s;position:relative;overflow:hidden}
.vm-card:hover{border-color:var(--b2)}.vm-card.sel{border-color:var(--amber)}
.vm-card::before{content:'';position:absolute;left:0;top:0;bottom:0;width:2px;border-radius:2px 0 0 2px}
.st-run::before{background:var(--green)}.st-stop::before{background:var(--red)}.st-clone::before{background:var(--amber)}.st-conf::before{background:var(--blue)}.st-pend::before{background:var(--text3)}
.vc-top{display:flex;align-items:center;gap:7px;margin-bottom:7px}
.vc-icon{width:26px;height:26px;border-radius:var(--rad);display:flex;align-items:center;justify-content:center;font-size:13px;flex-shrink:0}
.vc-name{font-size:12.5px;font-weight:600;overflow:hidden;white-space:nowrap;text-overflow:ellipsis}
.vc-ip{font-size:10.5px;color:var(--text2);font-family:var(--mono)}
.vc-tag{padding:1px 6px;border-radius:var(--rad);font-size:9px;font-family:var(--mono);font-weight:600;text-transform:uppercase;letter-spacing:.05em;white-space:nowrap;flex-shrink:0}
.vc-bar{height:2px;background:var(--panel3);border-radius:1px;margin-bottom:7px;overflow:hidden}
.vc-bar-fill{height:100%;transition:width .6s ease}
.vc-meta{display:flex;gap:8px;flex-wrap:wrap}
.vc-m{font-size:10px;color:var(--text3)}

#dp{width:300px;flex-shrink:0;background:var(--panel);border-left:1px solid var(--b1);display:none;flex-direction:column;overflow:hidden}
#dp.open{display:flex}
.vd-header{display:flex;align-items:center;gap:12px;padding:18px 22px 14px;border-bottom:1px solid var(--b1);background:var(--panel);flex-shrink:0}
.vd-icon{width:36px;height:36px;border-radius:var(--rad2);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.vd-title{font-size:17px;font-weight:600;letter-spacing:-.02em}
.vd-sub{font-size:11.5px;color:var(--text2);margin-top:3px;display:flex;align-items:center;gap:7px;flex-wrap:wrap}
.vd-tabs{display:flex;gap:1px;padding:0 22px;border-bottom:1px solid var(--b1);background:var(--panel);flex-shrink:0}
.vd-tab{padding:9px 14px;font-size:12.5px;font-weight:500;color:var(--text2);cursor:pointer;border-bottom:2px solid transparent;transition:all .12s;margin-bottom:-1px;white-space:nowrap}
.vd-tab:hover{color:var(--text)}.vd-tab.act{color:var(--amber);border-bottom-color:var(--amber)}
.vd-pane{padding:20px 22px;display:none}.vd-pane.act{display:block}
.vd-stats{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-bottom:16px}
.vd-stat{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);padding:11px 13px}
.vd-stat-v{font-size:20px;font-weight:600;font-family:var(--mono);line-height:1.2}
.vd-stat-l{font-size:9.5px;color:var(--text2);margin-top:3px;text-transform:uppercase;letter-spacing:.07em}
.res-bar{height:6px;background:var(--panel3);border-radius:3px;overflow:hidden;margin:3px 0 1px}
.res-bar-f{height:100%;border-radius:3px;transition:width .6s ease}
.res-row{margin-bottom:11px}
.res-lbl{display:flex;justify-content:space-between;font-size:11.5px;margin-bottom:2px;color:var(--text2)}
.res-lbl span:last-child{color:var(--text);font-family:var(--mono)}
.ads{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);margin-bottom:10px;overflow:hidden}
.ads-h{padding:9px 13px;background:var(--panel2);border-bottom:1px solid var(--b1);font-size:12px;font-weight:600;display:flex;align-items:center;gap:6px}
.ads-b{padding:13px}
.ck-row{display:flex;align-items:center;gap:7px;margin-bottom:7px;font-size:12px;color:var(--text)}
.ck-row input[type=checkbox]{width:14px;height:14px;accent-color:var(--amber);cursor:pointer;flex-shrink:0}
input[type=checkbox]{accent-color:var(--amber)}
.scope-card{background:var(--panel2);border:1px solid var(--b1);border-radius:var(--rad);padding:9px;margin-bottom:8px}

.dp-head{padding:11px 13px;border-bottom:1px solid var(--b1);display:flex;align-items:center;gap:7px;flex-shrink:0}
.dp-hic{width:26px;height:26px;border-radius:var(--rad);display:flex;align-items:center;justify-content:center;font-size:13px;flex-shrink:0}
.dp-htitle{font-weight:600;font-size:13px}
.dp-hsub{font-size:10.5px;color:var(--text2);margin-top:1px}
.dp-x{margin-left:auto;background:none;border:none;color:var(--text3);cursor:pointer;padding:4px;border-radius:var(--rad);transition:all .1s;display:flex;align-items:center;line-height:0}
.dp-x:hover{background:var(--panel2);color:var(--text)}
.dp-scroll{flex:1;overflow-y:auto}
.dp-scroll::-webkit-scrollbar{width:3px}
.dp-sec{padding:11px 13px;border-bottom:1px solid var(--b1)}
.dp-sec:last-child{border-bottom:none}
.dp-sec-title{font-size:9px;font-family:var(--mono);color:var(--text3);text-transform:uppercase;letter-spacing:.1em;font-weight:500;margin-bottom:7px}
.dp-row{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:4px}.dp-row:last-child{margin-bottom:0}
.dp-k{font-size:11.5px;color:var(--text2)}.dp-v{font-size:11.5px;font-family:var(--mono);text-align:right;max-width:165px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.dp-actions{padding:11px 13px;display:flex;flex-direction:column;gap:5px}
.power-row{display:grid;grid-template-columns:1fr 1fr;gap:5px;margin-bottom:5px}

.btn{display:inline-flex;align-items:center;justify-content:center;gap:4px;padding:5px 12px;border-radius:var(--rad);font-family:var(--sans);font-size:12px;font-weight:500;cursor:pointer;transition:all .1s;border:1px solid transparent;text-decoration:none;white-space:nowrap}
.btn-a{background:var(--amber);color:#000;border-color:var(--amber)}.btn-a:hover{opacity:.9}
.btn-g{background:transparent;color:var(--text2);border-color:var(--b2)}.btn-g:hover{color:var(--text);background:var(--panel2);border-color:var(--b3)}
.btn-d{background:transparent;color:var(--red);border-color:rgba(240,80,80,.2)}.btn-d:hover{background:var(--red-d)}
.btn-dep{background:var(--green);color:#000;font-weight:600;font-family:var(--mono);font-size:11.5px;letter-spacing:.04em}.btn-dep:hover{filter:brightness(1.1)}.btn-dep:disabled{opacity:.3;cursor:not-allowed}
.btn-abort{background:transparent;color:var(--red);border:1px solid rgba(240,80,80,.3);font-family:var(--mono);font-size:11.5px}.btn-abort:hover{background:var(--red-d)}
.btn-sm{padding:3px 9px;font-size:11px}.btn-fw{width:100%}
.btn-power{padding:4px 8px;font-size:11px;border-radius:var(--rad)}
.btn-start{color:var(--green);border-color:rgba(62,207,93,.2)}.btn-start:hover{background:var(--green-d)}
.btn-stop{color:var(--red);border-color:rgba(240,80,80,.2)}.btn-stop:hover{background:var(--red-d)}
.btn-reboot{color:var(--blue);border-color:rgba(91,156,246,.2)}.btn-reboot:hover{background:var(--blue-d)}
.btn-rdp{color:var(--amber);border-color:var(--amber-b);background:transparent}.btn-rdp:hover{background:var(--amber-d)}
.btn-console{color:var(--text2);border-color:var(--b2)}.btn-console:hover{background:var(--panel2)}

.ff{margin-bottom:9px}
.ff label{display:block;font-size:10.5px;color:var(--text2);margin-bottom:3px;font-weight:500;letter-spacing:.02em}
.ff input,.ff select,.ff textarea{width:100%;background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:5px 8px;border-radius:var(--rad);font-size:12px;font-family:var(--sans);outline:none;transition:border-color .12s;appearance:none}
.ff input:focus,.ff select:focus,.ff textarea:focus{border-color:var(--amber)}
.ff input::placeholder,.ff textarea::placeholder{color:var(--text3)}
.ff select{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6'%3E%3Cpath d='M0 0l5 6 5-6z' fill='%237a91ae'/%3E%3C/svg%3E");background-repeat:no-repeat;background-position:right 8px center;padding-right:24px}
.ff select option{background:var(--panel2)}
.g2{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.g3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px}

.sg{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);margin-bottom:10px;overflow:hidden}
.sg-head{padding:9px 13px;border-bottom:1px solid var(--b1);font-size:12.5px;font-weight:600;display:flex;align-items:center;gap:6px;background:var(--panel2)}
.sg-body{padding:13px}

.sc{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);margin-bottom:10px;overflow:hidden}
.sc-head{padding:9px 13px;border-bottom:1px solid var(--b1);display:flex;align-items:center;gap:6px;background:var(--panel2)}
.sc-head h3{font-size:12.5px;font-weight:600}
.sc-body{padding:13px}
.steps{display:flex;flex-direction:column}
.step{display:flex;gap:9px;padding:6px 0}
.step-dc{display:flex;flex-direction:column;align-items:center;width:18px;flex-shrink:0}
.step-dot{width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-family:var(--mono);font-weight:600;border:1px solid;flex-shrink:0}
.step-line{width:1px;flex:1;min-height:4px;background:var(--b1);margin:2px 0}
.step.done .step-dot{background:var(--green-d);border-color:var(--green);color:var(--green)}
.step.active .step-dot{background:var(--amber-d);border-color:var(--amber);color:var(--amber);animation:blink .8s infinite}
.step.pend .step-dot{background:var(--panel2);border-color:var(--b1);color:var(--text3)}
.step-name{font-size:12px;font-weight:500}
.step-sub{font-size:10.5px;color:var(--text3)}

#log{background:#050810;border:1px solid var(--b1);border-radius:var(--rad);height:320px;overflow-y:auto;padding:9px 11px;font-family:var(--mono);font-size:10.5px;color:#94a3b8;line-height:1.7;white-space:pre-wrap;word-break:break-all}
.lg-play{color:#f59e0b;font-weight:600}.lg-task{color:#60a5fa}.lg-ok{color:#4ade80}.lg-changed{color:#fb923c}.lg-fail{color:#f87171;font-weight:600}.lg-skip{color:#4b5563}.lg-recap{color:#a78bfa;font-weight:600}.lg-dim{color:#374151}.lg-info{color:#94a3b8}
#log::-webkit-scrollbar{width:3px}#log::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}

/* History table */
.hist-table{width:100%;border-collapse:collapse;font-size:12px}
.hist-table th{text-align:left;padding:6px 10px;font-size:9px;color:var(--text3);text-transform:uppercase;letter-spacing:.08em;border-bottom:1px solid var(--b1)}
.hist-table td{padding:8px 10px;border-bottom:1px solid var(--b1);vertical-align:top}
.hist-table tr:last-child td{border-bottom:none}
.hist-table tr:hover td{background:var(--panel2)}

/* Templates */
.tmpl-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:8px}
.tmpl-card{background:var(--panel);border:1px solid var(--b1);border-radius:var(--rad2);padding:14px;cursor:pointer;transition:border-color .1s}
.tmpl-card:hover{border-color:var(--b2)}
.tmpl-name{font-size:13px;font-weight:600;margin-bottom:4px}
.tmpl-desc{font-size:11px;color:var(--text2);margin-bottom:10px}
.tmpl-meta{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px}
.tmpl-m{font-size:10px;color:var(--text3)}
.tmpl-actions{display:flex;gap:5px}

/* Users */
.user-table{width:100%;border-collapse:collapse;font-size:12px}
.user-table th{text-align:left;padding:6px 10px;font-size:9px;color:var(--text3);text-transform:uppercase;letter-spacing:.08em;border-bottom:1px solid var(--b1)}
.user-table td{padding:8px 10px;border-bottom:1px solid var(--b1)}
.user-table tr:last-child td{border-bottom:none}

.sep{height:1px;background:var(--b1);margin:7px 0}
.pill{display:inline-block;padding:1px 6px;border-radius:8px;font-size:9.5px;font-family:var(--mono);font-weight:500}
.empty{text-align:center;padding:36px 0;color:var(--text3)}.empty p{font-size:12px;margin-top:6px}

#deploy-status-bar{display:none;align-items:center;gap:8px;padding:6px 14px;background:var(--panel2);border-bottom:1px solid var(--b1);font-size:11px;font-family:var(--mono);color:var(--text2)}
#deploy-status-bar.visible{display:flex}
.dsb-dot{width:6px;height:6px;border-radius:50%;background:var(--amber);animation:blink .8s infinite;flex-shrink:0}

#modal-bg{position:fixed;inset:0;background:rgba(0,0,0,.65);display:none;align-items:center;justify-content:center;z-index:100;backdrop-filter:blur(2px)}
#modal-bg.open{display:flex}
#modal{background:var(--panel);border:1px solid var(--b2);border-radius:var(--rad2);width:460px;max-height:88vh;overflow-y:auto;box-shadow:0 20px 60px rgba(0,0,0,.7)}
#modal::-webkit-scrollbar{width:3px}#modal::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}
.mhd{padding:12px 16px;border-bottom:1px solid var(--b1);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--panel);z-index:1}
.mhd h3{font-size:13px;font-weight:600}
.mbd{padding:16px}.mft{padding:9px 16px;border-top:1px solid var(--b1);display:flex;gap:5px;justify-content:flex-end;position:sticky;bottom:0;background:var(--panel)}

#toast{position:fixed;bottom:20px;right:20px;background:var(--red-d);border:1px solid var(--red);color:var(--text);padding:10px 14px;border-radius:var(--rad2);font-size:12px;font-family:var(--mono);z-index:999;display:none;max-width:360px;word-break:break-word}
#toast.show{display:block;animation:fi .2s ease}
</style>
</head>
<body>
<!-- Login Screen -->
<div id="login-screen">
  <div class="login-box">
    <div class="login-logo">
      <div class="login-logo-mark"><svg viewBox="0 0 24 24"><path d="M13 3L4 14h8l-1 7 9-11h-8z"/></svg></div>
      <span class="login-logo-name">windows-deployment</span>
    </div>
    <div class="login-title">Sign in</div>
    <div class="login-sub">Sign in with your account credentials</div>
    <div class="login-err" id="login-err"></div>
    <div class="ff"><label>Username</label><input id="login-user" autocomplete="username" placeholder="admin" data-1p-ignore="false" data-lpignore="false"></div>
    <div class="ff"><label>Password</label><input id="login-pass" type="password" autocomplete="current-password" placeholder="••••••••"></div>
    <button class="btn btn-a btn-fw" onclick="doLogin()" style="margin-top:4px">Sign in</button>
  </div>
</div>

<div id="deploy-status-bar">
  <div class="dsb-dot"></div>
  <span id="dsb-text">Deploy running…</span>
  <span style="margin-left:auto;cursor:pointer;color:var(--amber)" onclick="setView('deploy',null)">→ View log</span>
</div>

<div id="topbar">
  <div id="brand">
    <div id="brand-mark"><svg viewBox="0 0 24 24"><path d="M13 3L4 14h8l-1 7 9-11h-8z"/></svg></div>
    <span id="brand-name">windows-deployment</span>
  </div>
  <div id="topbar-div"></div>
  <div id="topnav">
    <button class="tnb act" onclick="setView('overview',this)">Overview</button>
    <button class="tnb" onclick="setView('deploy',this)">Deploy</button>
    <button class="tnb" onclick="setView('templates',this)">Templates</button>
    <button class="tnb" onclick="setView('settings',this)">Settings</button>
    <button class="tnb" id="btn-admin" onclick="setView('admin',this)" style="display:none">Admin</button>
  </div>
  <div id="topbar-right">
    <div class="conn-pill"><div class="cdot off" id="cdot"></div><span id="clab">No hosts</span></div>
    <div class="user-pill" onclick="openModal('user-menu')" id="user-pill" style="display:none">
      <span id="topbar-username"></span>
      <span class="role-badge" id="topbar-role"></span>
    </div>
  </div>
</div>

<div id="layout">
<div id="sidebar">
  <div id="sb-top">
    <div class="sb-search">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      <input id="sb-input" placeholder="Filter…" autocomplete="off" oninput="renderTree(this.value.toLowerCase())">
    </div>
    <button class="sb-plus" onclick="openModal('vm')" title="Add VM" id="btn-add-vm"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg></button>
    <button class="sb-icon" style="color:var(--amber);border-color:rgba(232,160,32,.3);background:rgba(232,160,32,.08)" onclick="openModal('host')" title="Add Host" id="btn-add-host"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg></button>
    <button class="sb-icon" style="color:var(--purple);border-color:rgba(167,139,250,.3);background:rgba(167,139,250,.08)" onclick="openModal('new-org')" title="New Organisation" id="btn-add-org"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></button>
  </div>
  <div id="tree"></div>
</div>

<div id="content">
<div id="main">

<!-- OVERVIEW -->
<div class="view active" id="view-overview">
  <div class="ph">
    <div class="ph-l"><div class="ph-title">Overview</div><div class="ph-sub" id="ov-sub">—</div></div>
    <div class="ph-r">
      <button class="btn btn-g btn-sm" onclick="renderAll()" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 005.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 013.51 15"/></svg> Refresh</button>
      <button class="btn btn-a btn-sm" onclick="openModal('vm')" id="btn-ov-add" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> Add VM</button>
    </div>
  </div>
  <div class="stat-row" id="stats"></div>
  <div class="grid-header">
    <span class="grid-label">Virtual Machines</span>
    <div class="filter-row">
      <button class="flt act" onclick="setFlt('all',this)">All</button>
      <button class="flt" onclick="setFlt('running',this)">Running</button>
      <button class="flt" onclick="setFlt('cloning',this)">Deploying</button>
      <button class="flt" onclick="setFlt('stopped',this)">Stopped</button>
    </div>
  </div>
  <div class="vm-grid" id="vmg"></div>
</div>

<!-- DEPLOY -->
<div class="view" id="view-deploy">
  <div class="ph">
    <div class="ph-l"><div class="ph-title">Deploy</div><div class="ph-sub" id="dep-sub">Select an organisation to deploy</div></div>
    <div class="ph-r" style="display:flex;gap:6px;align-items:center">
      <select id="dep-org-sel" onchange="onDepOrgChange(this.value)" style="background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:5px 8px;border-radius:var(--rad);font-size:12px;font-family:var(--sans);min-width:180px;outline:none">
        <option value="">- Select Organisation -</option>
      </select>
      <button class="btn btn-dep" id="dep-btn" onclick="startDeploy()" style="display:inline-flex;align-items:center;gap:6px" disabled><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg> Deploy</button>
      <button class="btn btn-abort" id="abort-btn" onclick="abortDeploy()" style="display:none;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg> Abort</button>
    </div>
  </div>
  <!-- Admin: active deploys overview -->
  <div id="admin-deploys-panel" style="display:none;margin-bottom:14px">
    <div class="sc">
      <div class="sc-head" style="justify-content:space-between">
        <h3>Active Deployments</h3>
        <span style="font-size:10px;color:var(--text3);font-family:var(--mono)" id="admin-dep-upd"></span>
      </div>
      <div class="sc-body" style="padding:0"><div id="admin-dep-list"></div></div>
    </div>
  </div>
  <div style="display:grid;grid-template-columns:1fr 280px;gap:14px">
    <div>
      <div class="sc">
        <div class="sc-head"><span style="color:var(--amber);font-size:11px">▸</span><h3>Queue</h3><span id="q-ct" style="margin-left:auto;font-size:10.5px;color:var(--text3);font-family:var(--mono)"></span></div>
        <div class="sc-body" style="padding:7px 12px"><div class="steps" id="dep-steps"></div></div>
      </div>
      <div class="sc">
        <div class="sc-head">
          <span style="font-family:var(--mono);color:var(--green);font-size:11.5px">$</span>
          <h3>Ansible Output</h3>
          <span id="live-b" style="margin-left:auto;display:flex;align-items:center;gap:8px"><span id="dep-progress" style="display:none;font-family:var(--mono);font-size:10px;color:var(--text3)"></span></span>
        </div>
        <div class="sc-body" style="padding:7px 9px"><div id="log"><span class="lg-info">// Select an organisation and click Deploy</span>
</div></div>
      </div>
      <div class="sc">
        <div class="sc-head"><h3>Deploy History</h3><button class="btn btn-g btn-sm" style="margin-left:auto;display:inline-flex;align-items:center;gap:4px" onclick="loadHistory()"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 005.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 013.51 15"/></svg></button></div>
        <div class="sc-body" style="padding:0">
          <table class="hist-table" id="hist-table">
            <thead><tr><th>Started</th><th>By</th><th>Organisation</th><th>VMs</th><th>Duration</th><th>Status</th></tr></thead>
            <tbody id="hist-body"></tbody>
          </table>
        </div>
      </div>
    </div>
    <div>
      <div class="sc">
        <div class="sc-head"><h3>Deployment Order</h3></div>
        <div class="sc-body" style="padding:5px 11px"><div id="role-order"></div></div>
      </div>
    </div>
  </div>
</div>

<!-- TEMPLATES -->
<div class="view" id="view-templates">
  <div class="ph">
    <div class="ph-l"><div class="ph-title">Deployment Templates</div><div class="ph-sub">Save and share VM configurations</div></div>
    <div class="ph-r">
      <button class="btn btn-g btn-sm" onclick="importTemplate()" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg> Import</button>
      <button class="btn btn-a btn-sm" onclick="openModal('new-template')" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> New Template</button>
    </div>
  </div>
  <div class="tmpl-grid" id="tmpl-grid"></div>
</div>

<!-- SETTINGS -->
<div class="view" id="view-settings">
  <div class="ph">
    <div class="ph-l"><div class="ph-title">Settings</div><div class="ph-sub">Application defaults — network and credentials are configured per organisation or host</div></div>
    <div class="ph-r"><button class="btn btn-a btn-sm" id="save-btn" onclick="saveSettings()" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Save</button></div>
  </div>
  <div class="sg">
    <div class="sg-head"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg> Default VM Resources</div>
    <div class="sg-body">
      <p style="font-size:11.5px;color:var(--text2);margin-bottom:12px">These are the default values pre-filled when adding a new VM. Override them per VM as needed.</p>
      <div class="g3">
        <div class="ff"><label>CPUs</label><input type="number" id="s-cpus" autocomplete="off" value="2" min="1" max="64"></div>
        <div class="ff"><label>RAM (MB)</label><input type="number" id="s-ram" autocomplete="off" value="4096" step="1024"></div>
        <div class="ff"><label>Disk (GB)</label><input type="number" id="s-disk" autocomplete="off" value="75" min="40"></div>
      </div>
    </div>
  </div>
  <div class="sg">
    <div class="sg-head"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> Locale & Timezone</div>
    <div class="sg-body">
      <p style="font-size:11.5px;color:var(--text2);margin-bottom:12px">Applied to every deployed Windows VM.</p>
      <div class="g2">
        <div class="ff"><label>Timezone</label><select id="s-tz">
          <option value="W. Europe Standard Time" selected>W. Europe Standard Time (CH/DE/AT)</option>
          <option value="UTC">UTC</option>
          <option value="GMT Standard Time">GMT Standard Time (UK)</option>
          <option value="Eastern Standard Time">Eastern Standard Time (US/East)</option>
          <option value="Pacific Standard Time">Pacific Standard Time (US/West)</option>
        </select></div>
        <div class="ff"><label>Locale</label><select id="s-locale">
          <option value="de-CH" selected>de-CH (Swiss German)</option>
          <option value="de-DE">de-DE (German)</option>
          <option value="en-US">en-US (English US)</option>
          <option value="en-GB">en-GB (English UK)</option>
          <option value="fr-CH">fr-CH (Swiss French)</option>
        </select></div>
      </div>
    </div>
  </div>
  <div class="sg">
    <div class="sg-head"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> Network & Credentials</div>
    <div class="sg-body">
      <p style="font-size:12px;color:var(--text2);line-height:1.6">
        Network settings (gateway, VLAN, DNS, bridge, storage) and the Windows Administrator password
        are configured <strong>per organisation</strong> or <strong>per host</strong> — not globally.<br><br>
        Go to <strong>Admin → Organisations</strong> to set these defaults, or configure them
        individually when adding a host.
      </p>
    </div>
  </div>
</div>

<!-- ADMIN -->
<div class="view" id="view-admin">
  <div class="ph">
    <div class="ph-l"><div class="ph-title">Administration</div><div class="ph-sub">Manage users and access</div></div>
    <div class="ph-r"></div>
  </div>
  <div class="sg" style="margin-bottom:10px">
    <div class="sg-head" style="display:flex;align-items:center;justify-content:space-between">
      <span style="display:flex;align-items:center;gap:6px"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg> Organisations</span>
      <button class="btn btn-a btn-sm" onclick="openModal('new-org')" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> New Organisation</button>
    </div>
    <div class="sg-body" style="padding:0"><div id="org-list"></div></div>
  </div>
  <div class="sg">
    <div class="sg-head" style="display:flex;align-items:center;justify-content:space-between"><span style="display:flex;align-items:center;gap:6px"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg> Users</span><button class="btn btn-a btn-sm" onclick="openModal('add-user')" style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> Add User</button></div>
    <div class="sg-body" style="padding:0">
      <table class="user-table" id="user-table">
        <thead><tr><th>Username</th><th>Role</th><th>Added</th><th></th></tr></thead>
        <tbody id="user-body"></tbody>
      </table>
    </div>
  </div>
</div>

</div><!-- #main -->
<div id="view-vm-detail" style="display:none;flex-direction:column;flex:1;overflow:hidden;background:var(--bg)">
  <div class="vd-header">
    <div class="vd-icon" id="vd-icon"></div>
    <div style="flex:1;min-width:0"><div class="vd-title" id="vd-title"></div><div class="vd-sub" id="vd-sub"></div></div>
    <div style="display:flex;gap:6px;flex-shrink:0" id="vd-actions"></div>
  </div>
  <div class="vd-tabs" id="vd-tabs"></div>
  <div id="vd-content" style="flex:1;overflow-y:auto"></div>
</div>
<div id="dp"><div class="dp-scroll"><div id="dp-body"></div></div></div>
</div><!-- #content -->
</div><!-- #layout -->

<div id="modal-bg" onclick="if(event.target===this)closeModal()" data-1p-ignore data-lpignore="true" autocomplete="off">
  <div id="modal">
    <div class="mhd"><h3 id="modal-title"></h3><button onclick="closeModal()" style="background:none;border:none;color:var(--text3);cursor:pointer;padding:4px;border-radius:var(--rad);display:flex;align-items:center;line-height:0"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button></div>
    <div class="mbd" id="modal-body"></div>
    <div class="mft" id="modal-foot"></div>
  </div>
</div>
<input type="file" id="file-import" accept=".json" style="display:none" onchange="handleImport(this)">
<div id="toast"></div>
<script>
// ── Constants ────────────────────────────────────────────────────────────────
const ROLES = {
  dc:             { label:'Domain Controller',  icon:'🛡', color:'#f59e0b', bg:'rgba(245,158,11,.1)',  order:0, dcpu:2, dram:4096 },
  fileserver:     { label:'File Server',        icon:'📁', color:'#5b9cf6', bg:'rgba(91,156,246,.1)',  order:1, dcpu:2, dram:4096 },
  backupserver:   { label:'Backup Server',      icon:'💾', color:'#a78bfa', bg:'rgba(167,139,250,.1)',order:2, dcpu:2, dram:4096 },
  rds_broker:     { label:'RDS Broker',         icon:'🔀', color:'#22d3ee', bg:'rgba(34,211,238,.1)', order:3, dcpu:2, dram:4096 },
  rds_sessionhost:{ label:'RDS Session Host',   icon:'🖥', color:'#3ecf5d', bg:'rgba(62,207,93,.1)',  order:4, dcpu:4, dram:8192 },
  printserver:    { label:'Print Server',       icon:'🖨', color:'#f97316', bg:'rgba(249,115,22,.1)', order:5, dcpu:2, dram:2048 },
  mgmt:           { label:'Management',         icon:'⚙',  color:'#94a3b8', bg:'rgba(148,163,184,.1)',order:6, dcpu:2, dram:4096 },
};
const ROLE_ORDER = Object.entries(ROLES).sort((a,b)=>a[1].order-b[1].order).map(([k])=>k);
const ST = {
  running:     { l:'Running',      c:'#3ecf5d', dot:'dot-run'  },
  stopped:     { l:'Stopped',      c:'#f05050', dot:'dot-stop' },
  cloning:     { l:'Cloning…',     c:'#e8a020', dot:'dot-clone'},
  configuring: { l:'Configuring…', c:'#5b9cf6', dot:'dot-conf' },
  pending:     { l:'Pending',      c:'#3d5470', dot:'dot-pend' },
};
const ST_CLS = { running:'st-run', stopped:'st-stop', cloning:'st-clone', configuring:'st-conf', pending:'st-pend' };

// ── Icon system — consistent SVG icons everywhere ────────────────────────────
const IC = {
  vm:       `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>`,
  host:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>`,
  org:      `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>`,
  plus:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  edit:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`,
  trash:    `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg>`,
  deploy:   `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>`,
  abort:    `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`,
  start:    `<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>`,
  stop:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><rect x="4" y="4" width="16" height="16" rx="2"/></svg>`,
  reboot:   `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>`,
  shutdown: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18.36 6.64a9 9 0 11-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>`,
  console:  `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>`,
  rdp:      `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`,
  link:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>`,
  export:   `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>`,
  import_:  `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`,
  save:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>`,
  refresh:  `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 005.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 013.51 15"/></svg>`,
  user:     `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`,
  key:      `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>`,
  logout:   `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>`,
  template: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>`,
  check:    `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>`,
};
// Helper: icon + label
const btn = (icon, label) => `<span style="display:inline-flex;align-items:center;gap:5px">${IC[icon]||''}${label}</span>`;

// ── State ────────────────────────────────────────────────────────────────────
let S = {
  orgs:[], hosts:[], vms:[], selVm:null, selHost:null, selOrg:null, flt:'all', view:'overview', deployOrgId:'', _pveStatus:{},
  deploying:false, session:null,
  settings:{ net:'172.16.10', gw:'172.16.10.1', pfx:24, dns1:'8.8.8.8', dns2:'1.1.1.1', vlan:'', cpus:2, ram:4096, disk:75, pass:'Asdf1234!', tz:'W. Europe Standard Time', locale:'de-CH' }
};

const $  = id => document.getElementById(id);
const ob = id => S.orgs.find(o => o.id === id);
const hb = id => S.hosts.find(h => h.id === id);
const vb = id => S.vms.find(v => v.id === id);
const q  = () => ($('sb-input')||{}).value?.toLowerCase() || '';

// ── Auth helpers ─────────────────────────────────────────────────────────────
function getToken() { return localStorage.getItem('wd_token'); }
function setToken(t) { localStorage.setItem('wd_token', t); }
function clearToken() { localStorage.removeItem('wd_token'); }

async function api(method, path, body) {
  const opts = { method, headers:{'Content-Type':'application/json','x-session': getToken()||''} };
  if (body !== undefined) opts.body = JSON.stringify(body);
  const r = await fetch(path, opts);
  if (r.status === 401) { showLogin(); throw new Error('Not authenticated'); }
  const d = await r.json();
  if (!r.ok) throw new Error(d.error || r.statusText);
  return d;
}

// ── Login / Logout ────────────────────────────────────────────────────────────
async function doLogin() {
  const user = $('login-user').value.trim();
  const pass = $('login-pass').value;
  if (!user || !pass) return;
  const err = $('login-err');
  err.className = 'login-err';
  try {
    const d = await fetch('/api/auth/login', {
      method: 'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ username: user, password: pass })
    });
    const data = await d.json();
    if (!d.ok) { err.textContent = data.error || 'Login failed'; err.className = 'login-err show'; return; }
    setToken(data.token);
    S.session = { username: data.username, role: data.role };
    hideLogin();
    await initApp();
  } catch(e) { err.textContent = e.message; err.className = 'login-err show'; }
}

$('login-pass').addEventListener('keydown', e => { if (e.key === 'Enter') doLogin(); });

function showLogin() { $('login-screen').style.display = 'flex'; clearToken(); S.session = null; }
function hideLogin() {
  $('login-screen').style.display = 'none';
  // Clear credentials from DOM so password managers don't re-trigger
  const u = $('login-user'), p = $('login-pass');
  if (u) u.value = '';
  if (p) p.value = '';
}

async function doLogout() {
  try { await api('POST', '/api/auth/logout'); } catch(_) {}
  showLogin(); closeModal();
}

function applyRoleUI() {
  const role = S.session?.role;
  $('topbar-username').textContent = S.session?.username || '';
  const rb = $('topbar-role');
  rb.textContent = role; rb.className = `role-badge role-${role}`;
  $('user-pill').style.display = '';
  $('btn-admin').style.display = role === 'admin' ? '' : 'none';
  $('btn-add-host').style.display = role === 'admin' ? '' : 'none';
  $('btn-add-vm').style.display = role !== 'readonly' ? '' : 'none';
  $('btn-ov-add').style.display = role !== 'readonly' ? '' : 'none';
  $('dep-btn').style.display = role !== 'readonly' ? '' : 'none';
}

// ── Toast ─────────────────────────────────────────────────────────────────────
function toast(msg, isErr=true) {
  const t = $('toast');
  t.textContent = msg;
  t.style.background = isErr ? 'var(--red-d)' : 'var(--green-d)';
  t.style.borderColor = isErr ? 'var(--red)' : 'var(--green)';
  t.className = 'show'; clearTimeout(t._to);
  t._to = setTimeout(() => t.className = '', 4000);
}

// ── Views ─────────────────────────────────────────────────────────────────────
function setView(v, btn) {
  S.view = v;
  $('view-vm-detail').style.display='none'; $('main').style.display=''; clearInterval(_vdResTimer); _vdId=null; S.selVm=null;
  document.querySelectorAll('.view').forEach(e => e.classList.remove('active'));
  $('view-'+v).classList.add('active');
  document.querySelectorAll('.tnb').forEach(b => b.classList.remove('act'));
  if (!btn) document.querySelectorAll('.tnb').forEach(b => { if (b.getAttribute('onclick')?.includes("'"+v+"'")) b.classList.add('act'); });
  else btn.classList.add('act');
  if (v === 'deploy') {
    populateDepOrgSel(); renderDeploy(); loadHistory();
    if (S.session?.role === 'admin') {
      $('admin-deploys-panel').style.display = '';
      pollAdminDeploys();
      clearInterval(_adminDepInterval);
      _adminDepInterval = setInterval(pollAdminDeploys, 5000);
    }
  }
  else { clearInterval(_adminDepInterval); }
  if (v === 'templates') loadTemplates();
  if (v === 'admin')     { loadOrgs(); loadUsers(); }
  if (v === 'settings')  syncSettingsForm();
}
function setFlt(f, btn) {
  S.flt = f;
  document.querySelectorAll('.flt').forEach(b => b.classList.remove('act'));
  btn.classList.add('act'); renderGrid();
}

// ── Load all state from backend ───────────────────────────────────────────────
async function loadState() {
  try {
    const [orgs, hosts, vms, settings] = await Promise.all([
      api('GET', '/api/organisations'),
      api('GET', '/api/hosts'),
      api('GET', '/api/vms'),
      api('GET', '/api/settings'),
    ]);
    S.orgs = orgs; S.hosts = hosts; S.vms = vms;
  } catch(e) { if (!e.message.includes('authenticated')) toast('Failed to load state: ' + e.message); }
}

// ── Tree ──────────────────────────────────────────────────────────────────────
function renderHostNode(h, qv) {
  const vms = S.vms.filter(v => v.hostId===h.id && (!qv || v.hostname.toLowerCase().includes(qv) || (ROLES[v.role]?.label||'').toLowerCase().includes(qv)));
  const run = vms.filter(v => v.status==='running').length;
  const open = h._open !== false;
  const div = document.createElement('div'); div.className='tr-host';
  div.innerHTML = `
    <div class="tr-host-row${h.id===S.selHost?' sel':''}" onclick="clickHost('${h.id}')">
      <svg class="tr-chv${open?' open':''}" id="chv-${h.id}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="m9 18 6-6-6-6"/></svg>
      <div class="tr-host-ic"><svg width="9" height="9" viewBox="0 0 24 24" fill="#e8a020"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg></div>
      <span class="tr-host-name">${h.name}</span>
      <span class="tr-cnt" style="background:${run?'rgba(62,207,93,.12)':'rgba(61,84,112,.2)'};color:${run?'var(--green)':'var(--text3)'}">${run}/${vms.length}</span>
    </div>
    <div class="tr-kids" id="kids-${h.id}" style="display:${open?'block':'none'}">
      ${vms.length ? '' : '<div class="tr-empty">No VMs</div>'}
      ${vms.map(v => { const r=ROLES[v.role]||{}; const s=ST[v.status]||ST.pending;
        return `<div class="tr-vm${v.id===S.selVm?' sel':''}" onclick="clickVm('${v.id}')">
          <div class="tr-dot ${s.dot}"></div><span class="tr-vm-ic">${r.icon||'□'}</span>
          <span class="tr-vm-name">${v.hostname}</span><span class="tr-vm-ip">${v.ip}</span>
        </div>`;
      }).join('')}
    </div>`;
  return div;
}

function renderTree(qv = '') {
  const t = $('tree'); t.innerHTML = '';
  if (!S.hosts.length && !S.orgs.length) {
    t.innerHTML = '<div class="tr-empty" style="padding:14px 10px">Add an organisation or host to begin</div>';
    return;
  }
  // Render organisations (with their hosts inside)
  S.orgs.forEach(org => {
    const orgHosts = S.hosts.filter(h => h.orgId === org.id);
    const orgVms = S.vms.filter(v => orgHosts.some(h => h.id===v.hostId));
    const orgRun = orgVms.filter(v => v.status==='running').length;
    const open = org._open !== false;
    const el = document.createElement('div'); el.className = 'tr-org';
    const hdr = document.createElement('div');
    hdr.className = `tr-org-row${org.id===S.selOrg?' sel':''}`;
    hdr.innerHTML = `
      <svg class="tr-chv${open?' open':''}" id="ochv-${org.id}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="m9 18 6-6-6-6"/></svg>
      <span style="display:flex;align-items:center;color:var(--purple)"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></span>
      <span class="tr-org-name">${org.name}</span>
      <span class="tr-cnt" style="background:${orgRun?'rgba(62,207,93,.12)':'rgba(167,139,250,.1)'};color:${orgRun?'var(--green)':'var(--purple)'}">${orgRun}/${orgVms.length}</span>`;
    hdr.onclick = () => clickOrg(org.id);
    const kids = document.createElement('div');
    kids.className = 'tr-org-kids'; kids.id = 'okids-'+org.id;
    kids.style.display = open ? 'block' : 'none';
    if (orgHosts.length) {
      orgHosts.forEach(h => kids.appendChild(renderHostNode(h, qv)));
    } else {
      kids.innerHTML = '<div class="tr-empty">No hosts in this organisation</div>';
    }
    el.appendChild(hdr); el.appendChild(kids);
    t.appendChild(el);
  });
  // Unassigned hosts
  const unassigned = S.hosts.filter(h => !h.orgId || !S.orgs.find(o => o.id===h.orgId));
  if (unassigned.length) {
    if (S.orgs.length) {
      const sep = document.createElement('div');
      sep.style.cssText = 'font-size:9px;color:var(--text3);padding:6px 10px 2px;text-transform:uppercase;letter-spacing:.07em';
      sep.textContent = 'Unassigned';
      t.appendChild(sep);
    }
    unassigned.forEach(h => t.appendChild(renderHostNode(h, qv)));
  }
}

function clickOrg(id) {
  const org = S.orgs.find(o => o.id===id); if (!org) return;
  org._open = !org._open;
  const kids = $('okids-'+id); if (kids) kids.style.display = org._open ? 'block' : 'none';
  const chv = $('ochv-'+id); if (chv) chv.classList.toggle('open', org._open);
  S.selOrg = id; S.selHost = null; S.selVm = null;
  showOrgDetail(id); renderTree(q());
}

function clickHost(id) {
  const h = S.hosts.find(x => x.id===id); if (!h) return;
  h._open = !h._open;
  const kids = $('kids-'+id); if (kids) kids.style.display = h._open ? 'block' : 'none';
  const chv = $('chv-'+id); if (chv) chv.classList.toggle('open', h._open);
  S.selHost = id; S.selOrg = null; S.selVm = null; showHostDetail(id); renderTree(q());
}
function clickVm(id) { S.selVm=id; S.selHost=null; S.selOrg=null; renderTree(q()); renderGrid(); showVmDetail(id); }
function closeDetail() { S.selVm=null; S.selHost=null; S.selOrg=null; $('dp').classList.remove('open'); $('view-vm-detail').style.display='none'; clearInterval(_vdResTimer); renderTree(q()); renderGrid(); }

// ── Authenticated file downloads ─────────────────────────────────────────────
async function downloadRdp(vmId, hostname) {
  try {
    const token = getToken();
    const res = await fetch(`/api/vms/${vmId}/rdp`, { headers: { 'x-session': token } });
    if (!res.ok) { toast('RDP download failed: ' + (await res.json()).error); return; }
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `${hostname}.rdp`;
    a.click(); URL.revokeObjectURL(url);
  } catch(e) { toast(e.message); }
}

async function exportTemplate(templateId, templateName) {
  try {
    const token = getToken();
    const res = await fetch(`/api/templates/${templateId}/export`, { headers: { 'x-session': token } });
    if (!res.ok) { toast('Export failed: ' + (await res.json()).error); return; }
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const safeName = (templateName||'template').replace(/[^a-z0-9]/gi,'_');
    a.href = url; a.download = `${safeName}.json`;
    a.click(); URL.revokeObjectURL(url);
  } catch(e) { toast(e.message); }
}

function showOrgDetail(id) {
  const org = ob(id); if (!org) return;
  const orgHosts = S.hosts.filter(h => h.orgId===org.id);
  const orgVms   = S.vms.filter(v => orgHosts.some(h=>h.id===v.hostId));
  const canAdmin  = S.session?.role==='admin';
  const d = org.defaults || {};
  $('dp').classList.add('open');
  $('dp-body').innerHTML = `
    <div class='dp-head'>
      <div class='dp-hic' style='background:rgba(167,139,250,.1);border:1px solid rgba(167,139,250,.3);display:flex;align-items:center;justify-content:center;color:var(--purple)'><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></div>
      <div style='flex:1'><div class='dp-htitle'>${org.name}</div><div class='dp-hsub'>${org.description||'No description'}</div></div>
      <button class='dp-x' onclick='closeDetail()'><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
    </div>
    <div class='dp-sec'>
      <div class='dp-sec-title'>Overview</div>
      <div class='dp-row'><span class='dp-k'>Hosts</span><span class='dp-v'>${orgHosts.length}</span></div>
      <div class='dp-row'><span class='dp-k'>VMs</span><span class='dp-v'>${orgVms.length}</span></div>
      <div class='dp-row'><span class='dp-k'>Running</span><span class='dp-v' style='color:var(--green)'>${orgVms.filter(v=>v.status==='running').length}</span></div>
    </div>
    ${Object.keys(d).length ? `
    <div class='dp-sec'>
      <div class='dp-sec-title'>Organisation Defaults</div>
      ${d.gateway?`<div class='dp-row'><span class='dp-k'>Gateway</span><span class='dp-v'>${d.gateway}</span></div>`:''}
      ${d.vlan?`<div class='dp-row'><span class='dp-k'>Default VLAN</span><span class='dp-v'>${d.vlan}</span></div>`:''}
      ${d.storage?`<div class='dp-row'><span class='dp-k'>Storage</span><span class='dp-v'>${d.storage}</span></div>`:''}
      ${d.bridge?`<div class='dp-row'><span class='dp-k'>Bridge</span><span class='dp-v'>${d.bridge}</span></div>`:''}
      ${d.templateName?`<div class='dp-row'><span class='dp-k'>Template</span><span class='dp-v'>${d.templateName}</span></div>`:''}
    </div>` : ''}
    <div class='dp-actions'>
      ${canAdmin ? `
        <button class='btn btn-a btn-fw' onclick="openModal('add-host-to-org','${org.id}')" style='display:inline-flex;align-items:center;justify-content:center;gap:6px'><svg width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='2' y='2' width='20' height='8' rx='2'/><rect x='2' y='14' width='20' height='8' rx='2'/><line x1='6' y1='6' x2='6.01' y2='6'/><line x1='6' y1='18' x2='6.01' y2='18'/></svg> Add Host to Org</button>
        <button class='btn btn-g btn-fw' onclick="openModal('edit-org','${org.id}')" style='display:inline-flex;align-items:center;justify-content:center;gap:6px'><svg width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7'/><path d='M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z'/></svg> Edit Organisation</button>
        <div class='sep'></div>
        <button class='btn btn-d btn-fw' onclick="delOrg('${org.id}')" style='display:inline-flex;align-items:center;justify-content:center;gap:6px'><svg width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='3 6 5 6 21 6'/><path d='M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6'/></svg> Delete Organisation</button>
      ` : ''}
    </div>`;
}

// ── Overview ──────────────────────────────────────────────────────────────────
function renderOverview() {
  const tot=S.vms.length, run=S.vms.filter(v=>v.status==='running').length,
        dep=S.vms.filter(v=>['cloning','configuring'].includes(v.status)).length,
        stp=S.vms.filter(v=>v.status==='stopped').length;
  $('ov-sub').textContent = `${S.orgs.length} org${S.orgs.length!==1?'s':''} · ${S.hosts.length} host${S.hosts.length!==1?'s':''} · ${tot} VM${tot!==1?'s':''}`;
  $('stats').innerHTML = `
    <div class="stat-card"><div class="stat-v">${tot}</div><div class="stat-l">Total VMs</div></div>
    <div class="stat-card"><div class="stat-v" style="color:var(--green)">${run}</div><div class="stat-l">Running</div></div>
    <div class="stat-card"><div class="stat-v" style="color:var(--amber)">${dep}</div><div class="stat-l">Deploying</div></div>
    <div class="stat-card"><div class="stat-v" style="color:var(--red)">${stp}</div><div class="stat-l">Stopped</div></div>`;
  const n = S.hosts.length;
  $('cdot').className = 'cdot ' + (n ? 'on' : 'off');
  $('clab').textContent = n===0 ? 'No hosts' : n===1 ? S.hosts[0].name : `${n} hosts`;
  renderGrid();
}

function renderGrid() {
  const g = $('vmg');
  const vms = S.vms.filter(v => S.flt==='all' || v.status===S.flt);
  if (!vms.length) { g.innerHTML=`<div class="empty" style="grid-column:1/-1"><p>${S.vms.length?'No VMs match filter':'No VMs — click + Add VM'}</p></div>`; return; }
  g.innerHTML = vms.map(v => {
    const r=ROLES[v.role]||{}; const s=ST[v.status]||ST.pending;
    const bc=v.status==='running'?'var(--green)':v.status==='stopped'?'var(--red)':v.status==='cloning'?'var(--amber)':'var(--blue)';
    return `<div class="vm-card ${ST_CLS[v.status]||'st-pend'}${S.selVm===v.id?' sel':''}" onclick="clickVm('${v.id}')">
      <div class="vc-top">
        <div class="vc-icon" style="background:${r.bg}">${r.icon||'□'}</div>
        <div style="flex:1;min-width:0"><div class="vc-name">${v.hostname}</div><div class="vc-ip">${v.ip}</div></div>
        <span class="vc-tag" style="background:${s.c}18;color:${s.c}">${s.l}</span>
      </div>
      <div class="vc-bar"><div class="vc-bar-fill" style="width:${v.prog||0}%;background:${bc}"></div></div>
      <div class="vc-meta">
        <span class="vc-m">${v.cpus} vCPU</span><span class="vc-m">·</span>
        <span class="vc-m">${v.ram/1024}GB</span><span class="vc-m">·</span>
        <span class="vc-m">${v.disk}GB</span>
        ${v.vlan ? `<span class="vc-m">·</span><span class="vc-m">VLAN${v.vlan}</span>` : ''}
        <span class="vc-m" style="margin-left:auto;color:var(--text3)">
          ${(()=>{ const h=hb(v.hostId); const o=ob(h?.orgId); return o?o.name+' / '+h.name : h?.name||'?'; })()}
        </span>
      </div>
    </div>`;
  }).join('');
}

// ── Detail Panels ─────────────────────────────────────────────────────────────
// ── VM Detail View ────────────────────────────────────────────────────────────
let _vdTab = 'overview';
let _vdId  = null;
let _vdResTimer = null;

function showVmDetail(id) {
  const v = vb(id); if (!v) return;
  _vdId = id;
  document.querySelectorAll('.view').forEach(e => e.classList.remove('active'));
  $('main').style.display = 'none';
  $('view-vm-detail').style.display = 'flex';
  $('dp').classList.remove('open');
  document.querySelectorAll('.tnb').forEach(b => b.classList.remove('act'));
  _vdRenderHeader(v);
  _vdRenderTabs(v);
  _vdShowTab(_vdTab, v);
  clearInterval(_vdResTimer);
  _vdResTimer = setInterval(() => {
    const cur = vb(_vdId);
    if (cur && _vdTab === 'resources') $('vd-content').innerHTML = _vdPaneResources(cur);
  }, 10000);
}

function closeVmDetail() {
  clearInterval(_vdResTimer); _vdId = null; S.selVm = null;
  $('view-vm-detail').style.display = 'none';
  $('main').style.display = '';
  renderTree(q()); renderGrid();
  setView('overview', null);
}

function _vdRenderHeader(v) {
  const r = ROLES[v.role]||{}; const s = ST[v.status]||ST.pending;
  const h = hb(v.hostId); const org = ob(h?.orgId);
  const canEdit = S.session?.role !== 'readonly';
  $('vd-icon').style.background = r.bg||'var(--panel2)';
  $('vd-icon').textContent = r.icon||'\u25a1';
  $('vd-title').textContent = v.hostname;
  $('vd-sub').innerHTML =
    `<span style="color:${s.c};display:flex;align-items:center;gap:4px"><span class="tr-dot ${s.dot}" style="width:5px;height:5px;display:inline-block;border-radius:50%"></span>${s.l}</span>` +
    `<span style="color:var(--b3)">|</span><span>${r.label}</span>` +
    `<span style="color:var(--b3)">|</span><span style="font-family:var(--mono)">${v.ip}</span>` +
    (v.vlan ? `<span style="color:var(--b3)">|</span><span>VLAN ${v.vlan}</span>` : '') +
    `<span style="color:var(--b3)">|</span><span>${org?.name||'?'} / ${h?.name||'?'}</span>` +
    (v.vmid ? `<span style="color:var(--b3)">|</span><span style="font-family:var(--mono);color:var(--text3)">VMID ${v.vmid}</span>` : '');
  const pveBase = h ? `https://${h.host}:8006` : '#';
  const conUrl  = v.vmid ? `${pveBase}/?console=kvm&vmid=${v.vmid}&node=${h?.node||'pve'}` : null;
  const svgEdit = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`;
  const svgBack = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="15 18 9 12 15 6"/></svg>`;
  const svgCon  = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>`;
  const svgRdp  = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`;
  $('vd-actions').innerHTML =
    (conUrl ? `<a href="${conUrl}" target="_blank" class="btn btn-console btn-sm" style="display:inline-flex;align-items:center;gap:5px">${svgCon} Console</a>` : '') +
    `<button class="btn btn-rdp btn-sm" onclick="downloadRdp('${v.id}','${v.hostname}')" style="display:inline-flex;align-items:center;gap:5px">${svgRdp} .rdp</button>` +
    (canEdit ? `<button class="btn btn-g btn-sm" onclick="openModal('edit-vm','${v.id}')" style="display:inline-flex;align-items:center;gap:5px">${svgEdit} Edit</button>` : '') +
    (canEdit ? `<button class="btn btn-d btn-sm" onclick="delVm('${v.id}')" style="display:inline-flex;align-items:center;gap:5px"><svg width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='3 6 5 6 21 6'/><path d='M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6'/></svg> Remove</button>` : '') +
    `<button class="btn btn-g btn-sm" onclick="closeVmDetail()" style="display:inline-flex;align-items:center;gap:5px">${svgBack} Back</button>`;
}

function _vdRenderTabs(v) {
  const tabs = [
    { id:'overview',  label:'Overview' },
    ...(v.role === 'dc' ? [{ id:'ad', label:'AD / DNS / DHCP' }] : []),
    { id:'resources', label:'Resources' },
    { id:'power',     label:'Power' },
  ];
  $('vd-tabs').innerHTML = tabs.map(t =>
    `<div class="vd-tab${_vdTab===t.id?' act':''}" onclick="_vdShowTab('${t.id}')">${t.label}</div>`
  ).join('');
}

function _vdShowTab(tab, v) {
  _vdTab = tab;
  if (!v) v = vb(_vdId);
  if (!v) return;
  const labels = { overview:'Overview', ad:'AD / DNS / DHCP', resources:'Resources', power:'Power' };
  document.querySelectorAll('.vd-tab').forEach(t => t.classList.toggle('act', t.textContent.trim() === (labels[tab]||'')));
  const fns = { overview:_vdPaneOverview, ad:_vdPaneAD, resources:_vdPaneResources, power:_vdPanePower };
  $('vd-content').innerHTML = (fns[tab] || fns.overview)(v);
}

function _vdPaneOverview(v) {
  const s = ST[v.status]||ST.pending; const h = hb(v.hostId);
  const org = ob(h?.orgId); const od = org?.defaults||{};
  const gw = od.gateway||'--'; const dns1 = od.dns1||'--'; const dns2 = od.dns2||'--';
  const domain = v.domain||od.domain||'';
  const dep = ['cloning','configuring'].includes(v.status);
  return `<div class="vd-pane act">
    <div class="vd-stats">
      <div class="vd-stat"><div class="vd-stat-v" style="color:${s.c}">${s.l}</div><div class="vd-stat-l">Status</div></div>
      <div class="vd-stat"><div class="vd-stat-v">${v.cpus}</div><div class="vd-stat-l">vCPU</div></div>
      <div class="vd-stat"><div class="vd-stat-v">${(v.ram/1024).toFixed(0)} GB</div><div class="vd-stat-l">RAM</div></div>
      <div class="vd-stat"><div class="vd-stat-v">${v.disk} GB</div><div class="vd-stat-l">Disk</div></div>
    </div>
    ${dep ? `<div class="vc-bar" style="margin-bottom:14px"><div class="vc-bar-fill" style="width:${v.prog||0}%;background:${s.c}"></div></div>` : ''}
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div class="ads"><div class="ads-h">Network</div><div class="ads-b">
        <div class="dp-row"><span class="dp-k">IP</span><span class="dp-v" style="font-family:var(--mono)">${v.ip}</span></div>
        <div class="dp-row"><span class="dp-k">Gateway</span><span class="dp-v" style="font-family:var(--mono)">${gw}</span></div>
        <div class="dp-row"><span class="dp-k">DNS Primary</span><span class="dp-v" style="font-family:var(--mono)">${dns1}</span></div>
        <div class="dp-row"><span class="dp-k">DNS Secondary</span><span class="dp-v" style="font-family:var(--mono)">${dns2}</span></div>
        ${v.vlan ? `<div class="dp-row"><span class="dp-k">VLAN</span><span class="dp-v">${v.vlan}</span></div>` : ''}
        ${domain ? `<div class="dp-row"><span class="dp-k">Domain</span><span class="dp-v">${domain}</span></div>` : ''}
        <div class="dp-row"><span class="dp-k">RDP</span><span class="dp-v" style="color:var(--green)">Enabled</span></div>
      </div></div>
      <div class="ads"><div class="ads-h">Placement</div><div class="ads-b">
        <div class="dp-row"><span class="dp-k">Organisation</span><span class="dp-v">${org?.name||'--'}</span></div>
        <div class="dp-row"><span class="dp-k">Host</span><span class="dp-v">${h?.name||'--'}</span></div>
        <div class="dp-row"><span class="dp-k">Node</span><span class="dp-v">${h?.node||'--'}</span></div>
        ${v.vmid ? `<div class="dp-row"><span class="dp-k">VMID</span><span class="dp-v" style="font-family:var(--mono)">${v.vmid}</span></div>` : ''}
        <div class="dp-row"><span class="dp-k">Role</span><span class="dp-v">${ROLES[v.role]?.label||v.role}</span></div>
      </div></div>
    </div>
  </div>`;
}

function _dhcpScopeCard(i, s, ctx) {
  return `<div class="scope-card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
      <span style="font-size:11px;font-weight:600;color:var(--text2)">Scope ${i+1}</span>
      <button class="btn btn-d btn-sm" onclick="this.closest('.scope-card').remove()" style="padding:2px 7px">Remove</button>
    </div>
    <div class="g2" style="margin-bottom:6px">
      <div class="ff" style="margin-bottom:0"><label>Start IP</label><input class="sc-start" value="${s.start||''}" placeholder="${ctx.netpfx}.50" autocomplete="off"></div>
      <div class="ff" style="margin-bottom:0"><label>End IP</label><input class="sc-end" value="${s.end||''}" placeholder="${ctx.netpfx}.200" autocomplete="off"></div>
    </div>
    <div class="g3">
      <div class="ff" style="margin-bottom:0"><label>Subnet /</label><input class="sc-pfx" value="${s.pfx||'24'}" placeholder="24" autocomplete="off"></div>
      <div class="ff" style="margin-bottom:0"><label>Gateway</label><input class="sc-gw" value="${s.gw||ctx.gw||''}" placeholder="${ctx.gw||'172.16.10.1'}" autocomplete="off"></div>
      <div class="ff" style="margin-bottom:0"><label>Lease (d)</label><input class="sc-lease" value="${s.lease||'8'}" autocomplete="off"></div>
    </div>
  </div>`;
}

function _vdPaneAD(v) {
  const ac = v.adConfig||{}; const h = hb(v.hostId); const org = ob(h?.orgId); const od = org?.defaults||{};
  const ro = S.session?.role === 'readonly';
  const orgHosts = S.hosts.filter(hh => hh.orgId === h?.orgId);
  const otherDCs = S.vms.filter(vv => vv.id !== v.id && vv.role === 'dc' && orgHosts.some(hh => hh.id === vv.hostId));
  const dcOpts = otherDCs.map(d => `<option value="${d.id}"${ac.replPartner===d.id?' selected':''}>${d.hostname}</option>`).join('');
  const foOpts = otherDCs.map(d => `<option value="${d.id}"${ac.failPartner===d.id?' selected':''}>${d.hostname}</option>`).join('');
  const netpfx = od.netPrefix || od.gateway?.split('.').slice(0,3).join('.') || '172.16.10';
  const revZone = netpfx.split('.').reverse().join('.') + '.in-addr.arpa';
  const inp = (id,lbl,val,ph) => `<div class="ff"><label>${lbl}</label><input id="${id}" value="${val||''}" placeholder="${ph||''}" autocomplete="off"${ro?' readonly':''}></div>`;
  const ck  = (id,chk,lbl)   => `<div class="ck-row"><input type="checkbox" id="${id}"${chk?' checked':''}${ro?' disabled':''}><label for="${id}">${lbl}</label></div>`;
  const fsl = (id,lbl,opts)  => `<div class="ff"><label>${lbl}</label><select id="${id}"${ro?' disabled':''}><option value="">-- none --</option>${opts}</select></div>`;
  const scopes = (ac.dhcpScopes||[]).length > 0 ? (ac.dhcpScopes||[]).map((s,i) => _dhcpScopeCard(i,s,{netpfx,gw:od.gateway||''})).join('') : _dhcpScopeCard(0,{},{netpfx,gw:od.gateway||''});
  return `<div class="vd-pane act">
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div>
        <div class="ads"><div class="ads-h">Active Directory</div><div class="ads-b">
          ${inp('ad-domain','Domain Name',ac.domain||od.domain,'contoso.local')}
          ${inp('ad-netbios','NetBIOS',ac.netbios||(ac.domain||od.domain||'').split('.')[0]?.toUpperCase()||'','CONTOSO')}
          <div class="g2">
            <div class="ff"><label>Forest Mode</label><select id="ad-mode"${ro?' disabled':''}>${['WinThreshold','Win2016','Win2012R2'].map(m=>`<option value="${m}"${(ac.forestMode||'WinThreshold')===m?' selected':''}>${m==='WinThreshold'?'2025/2022':m}</option>`).join('')}</select></div>
            <div class="ff"><label>DSRM Password <span style='color:var(--text3);font-weight:400'>(must differ from admin pw)</span></label><input id="ad-safepw" type="text" data-1p-ignore value="${ac.safeModePw||''}" placeholder="e.g. DSRMpass123!" autocomplete="off"${ro?' readonly':''}></div>
          </div>
          <div style="border-top:1px solid var(--b1);padding-top:8px;margin-top:6px">
            ${ck('ad-primary',ac.isPrimary!==false,'Primary DC -- promote new forest')}
            ${ck('ad-rodc',!!ac.isRODC,'Read-Only DC (RODC)')}
          </div>
          <div style="border-top:1px solid var(--b1);padding-top:8px;margin-top:6px">
            ${otherDCs.length ? `
            ${ck('ad-repl',!!ac.enableRepl,'Enable AD Replication')}
            ${fsl('ad-repl-partner','Replication Partner',dcOpts)}` : `
            <div style="font-size:11px;color:var(--text3);padding:4px 0">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" style="vertical-align:middle;margin-right:4px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Add a second DC to this organisation to enable AD Replication
            </div>`}
          </div>
        </div></div>
      </div>
      <div>
        <div class="ads"><div class="ads-h">DNS Zones</div><div class="ads-b">
          <div style="background:var(--panel2);border:1px solid var(--b1);border-radius:var(--rad);padding:8px 10px;margin-bottom:10px;font-size:11px">
            <div style="display:flex;justify-content:space-between;margin-bottom:3px"><span style="color:var(--text3)">Forward</span><span style="font-family:var(--mono)">${ac.domain||od.domain||'contoso.local'}</span></div>
            <div style="display:flex;justify-content:space-between"><span style="color:var(--text3)">Reverse</span><span style="font-family:var(--mono)">${revZone}</span></div>
          </div>
          <div style="font-size:11px;color:var(--text2);margin-bottom:8px">Additional zones:</div>
          <div id="dns-zones-list">${(ac.dnsZones||[]).map(z=>`<div style="display:flex;gap:5px;margin-bottom:5px"><input value="${z}" class="dns-zone-inp" style="flex:1;background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:4px 7px;border-radius:var(--rad);font-size:11.5px" placeholder="extra.zone">${!ro?'<button class="btn btn-d btn-sm" onclick="this.parentElement.remove()" style="padding:2px 7px">x</button>':''}</div>`).join('')}</div>
          ${!ro ? '<button class="btn btn-g btn-sm" onclick="_addDnsZone()">+ Add Zone</button>' : ''}
        </div></div>
        <div class="ads"><div class="ads-h">DHCP Scopes</div><div class="ads-b">
          <div id="dhcp-scopes-list">${scopes}</div>
          ${!ro ? `<button class="btn btn-g btn-sm" onclick="_addDhcpScope('${v.id}')">+ Add Scope</button>` : ''}
          <div style="border-top:1px solid var(--b1);padding-top:9px;margin-top:9px">
            ${otherDCs.length ? `
            ${ck('dhcp-fo',!!ac.dhcpFailover,'DHCP Failover')}
            ${fsl('dhcp-fo-partner','Failover Partner',foOpts)}` : `
            <div style="font-size:11px;color:var(--text3);padding:4px 0">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" style="vertical-align:middle;margin-right:4px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Add a second DC to enable DHCP Failover
            </div>`}
          </div>
        </div></div>
      </div>
    </div>
    ${!ro ? `<div style="margin-top:10px;padding-top:12px;border-top:1px solid var(--b1);display:flex;gap:8px;align-items:center">
      <button class="btn btn-g" onclick="_saveAdConfig('${v.id}')" style="display:inline-flex;align-items:center;gap:6px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Save Config</button>
      <span style="font-size:11px;color:var(--text2);display:flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> AD setup runs automatically during deployment — DC is promoted before other servers are deployed</span>
    </div>` : ''}
  </div>`;
}

function _addDnsZone() {
  const list = $('dns-zones-list'); if (!list) return;
  const d = document.createElement('div'); d.style.cssText='display:flex;gap:5px;margin-bottom:5px';
  d.innerHTML = `<input class="dns-zone-inp" style="flex:1;background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:4px 7px;border-radius:var(--rad);font-size:11.5px" placeholder="extra.zone"><button class="btn btn-d btn-sm" onclick="this.parentElement.remove()" style="padding:2px 7px">x</button>`;
  list.appendChild(d);
}

function _addDhcpScope(vmId) {
  const v = vb(vmId); if (!v) return;
  const h = hb(v.hostId); const org = ob(h?.orgId); const od = org?.defaults||{};
  const netpfx = od.netPrefix || od.gateway?.split('.').slice(0,3).join('.') || '172.16.10';
  const list = $('dhcp-scopes-list'); if (!list) return;
  const n = list.querySelectorAll('.scope-card').length;
  const d = document.createElement('div');
  d.innerHTML = _dhcpScopeCard(n, {}, { netpfx, gw: od.gateway||'' });
  list.insertBefore(d.firstElementChild, list.lastElementChild);
}

async function _saveAdConfig(vmId) {
  const v = vb(vmId); if (!v) return;
  const ac = {
    domain:       $('ad-domain')?.value||'',
    netbios:      $('ad-netbios')?.value||'',
    forestMode:   $('ad-mode')?.value||'WinThreshold',
    safeModePw:   $('ad-safepw')?.value||'',
    isPrimary:    $('ad-primary')?.checked ?? true,
    isRODC:       !!$('ad-rodc')?.checked,
    enableRepl:   !!$('ad-repl')?.checked,
    replPartner:  $('ad-repl-partner')?.value||'',
    dhcpFailover: !!$('dhcp-fo')?.checked,
    failPartner:  $('dhcp-fo-partner')?.value||'',
    dnsZones:     [...(document.querySelectorAll('.dns-zone-inp')||[])].map(i=>i.value).filter(Boolean),
    dhcpScopes:   [...(document.querySelectorAll('.scope-card')||[])].map(el=>({
      start: el.querySelector('.sc-start')?.value||'',
      end:   el.querySelector('.sc-end')?.value||'',
      pfx:   el.querySelector('.sc-pfx')?.value||'24',
      gw:    el.querySelector('.sc-gw')?.value||'',
      lease: el.querySelector('.sc-lease')?.value||'8',
    })).filter(s=>s.start&&s.end),
  };
  // Validate DSRM password
  if (!ac.safeModePw) { toast('DSRM Password is required'); return; }
  const adminPw = (ob(hb(v.hostId)?.orgId)?.defaults?.pass) || '';
  if (adminPw && ac.safeModePw === adminPw) { toast('DSRM Password must differ from the Windows Admin Password'); return; }
  try {
    await api('PUT', `/api/vms/${vmId}`, { ...v, adConfig: ac });
    const idx = S.vms.findIndex(x => x.id === vmId);
    if (idx >= 0) S.vms[idx].adConfig = ac;
    toast('AD configuration saved', false);
  } catch(e) { toast(e.message); }
}

async function _runAdSetup(vmId) {
  const v = vb(vmId); if (!v || !v.vmid) { toast('VM must be deployed first'); return; }
  if (!confirm(`Run AD Setup on ${v.hostname}?\n\nThis connects via WinRM and:\n- Promotes the DC / installs AD DS\n- Creates DNS zones (forward + reverse)\n- Configures DHCP scopes\n\nMake sure the VM is fully booted.`)) return;
  await _saveAdConfig(vmId);
  try {
    await api('POST', `/api/vms/${vmId}/ad-setup`, {});
    toast('AD setup started -- watch the Deploy tab for the live log', false);
  } catch(e) { toast(e.message); }
}

function _vdPaneResources(v) {
  const p = S._pveStatus?.[v.hostname];
  if (!p) return `<div class="vd-pane act" style="text-align:center;padding:60px 0;color:var(--text3)">
    <div style="font-size:13px;margin-bottom:5px">No live data</div>
    <div style="font-size:11.5px">Available once the VM is deployed and running.</div>
  </div>`;
  const cpu = Math.round((p.cpu||0)*100);
  const mu = p.mem||0; const mm = p.maxmem||v.ram*1024*1024||1;
  const mpct = Math.round(mu/mm*100);
  const mgb = (mu/1073741824).toFixed(1); const mmax = (mm/1073741824).toFixed(1);
  const up = p.uptime ? _fmtUp(p.uptime) : '--';
  function bar(pct, c) { return `<div class="res-bar"><div class="res-bar-f" style="width:${pct}%;background:${c}"></div></div>`; }
  return `<div class="vd-pane act">
    <div class="vd-stats">
      <div class="vd-stat"><div class="vd-stat-v" style="color:${cpu>80?'var(--red)':cpu>60?'var(--amber)':'var(--green)'}">${cpu}%</div><div class="vd-stat-l">CPU</div></div>
      <div class="vd-stat"><div class="vd-stat-v">${mgb} GB</div><div class="vd-stat-l">RAM Used</div></div>
      <div class="vd-stat"><div class="vd-stat-v">${mmax} GB</div><div class="vd-stat-l">RAM Total</div></div>
      <div class="vd-stat"><div class="vd-stat-v">${up}</div><div class="vd-stat-l">Uptime</div></div>
    </div>
    <div style="max-width:580px">
      <div class="res-row"><div class="res-lbl"><span>CPU</span><span>${cpu}%</span></div>${bar(cpu, cpu>80?'var(--red)':cpu>60?'var(--amber)':'var(--green)')}</div>
      <div class="res-row"><div class="res-lbl"><span>RAM</span><span>${mgb} / ${mmax} GB</span></div>${bar(mpct, mpct>85?'var(--red)':mpct>70?'var(--amber)':'var(--blue)')}</div>
      <div style="margin-top:14px;font-size:11px;color:var(--text3)">Updated every 10 seconds from Proxmox API.</div>
    </div>
  </div>`;
}

function _fmtUp(s) {
  const d=Math.floor(s/86400), h=Math.floor((s%86400)/3600), m=Math.floor((s%3600)/60);
  return [d?d+'d':'', h?h+'h':'', m?m+'m':''].filter(Boolean).join(' ') || '<1m';
}

function _vdPanePower(v) {
  const can = S.session?.role !== 'readonly' && !!v.vmid;
  const dis = !can ? 'disabled' : '';
  const pb = (a,ico,lbl,cls) => `<button class="btn ${cls}" onclick="powerAction('${v.id}','${a}')" style="display:inline-flex;align-items:center;gap:6px;width:100%;justify-content:center;padding:10px" ${dis}>${ico} ${lbl}</button>`;
  const iPlay   = `<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>`;
  const iStop   = `<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><rect x="4" y="4" width="16" height="16" rx="2"/></svg>`;
  const iReboot = `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>`;
  const iPwr    = `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18.36 6.64a9 9 0 11-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>`;
  return `<div class="vd-pane act">
    ${!v.vmid ? `<div style="text-align:center;padding:60px 0;color:var(--text3)"><div style="font-size:13px;margin-bottom:5px">No VMID</div><div style="font-size:11.5px">Available after deployment.</div></div>` : `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;max-width:380px">
      ${pb('start',   iPlay,   'Start',      'btn-start')}
      ${pb('stop',    iStop,   'Force Off',  'btn-stop')}
      ${pb('reboot',  iReboot, 'Reboot',     'btn-reboot')}
      ${pb('shutdown',iPwr,    'Shutdown',   'btn-stop')}
    </div>
    <div style="margin-top:14px;font-size:11.5px;color:var(--text2)">
      <strong>Force Off</strong> -- immediate power cut.&nbsp;
      <strong>Shutdown</strong> -- graceful via guest agent.
    </div>`}
  </div>`;
}


function showHostDetail(id) {
  const h = hb(id); if (!h) return;
  const vms = S.vms.filter(v => v.hostId===id);
  const run = vms.filter(v => v.status==='running').length;
  const canEdit = S.session?.role === 'admin';
  $('dp').classList.add('open');
  $('dp-body').innerHTML = `
    <div class="dp-head">
      <div class="dp-hic" style="background:var(--amber-d);border:1px solid var(--amber-b)">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--amber)" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
      </div>
      <div style="flex:1"><div class="dp-htitle">${h.name}</div><div class="dp-hsub">${h.host} · ${h.node}</div></div>
      <button class="dp-x" onclick="closeDetail()"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">Connection</div>
      <div class="dp-row"><span class="dp-k">Host</span><span class="dp-v">${h.host}</span></div>
      <div class="dp-row"><span class="dp-k">Node</span><span class="dp-v">${h.node}</span></div>
      <div class="dp-row"><span class="dp-k">Template</span><span class="dp-v">${h.templateName||'—'}</span></div>
      <div class="dp-row"><span class="dp-k">Storage</span><span class="dp-v">${h.storage}</span></div>
      <div class="dp-row"><span class="dp-k">Bridge</span><span class="dp-v">${h.bridge}</span></div>
      ${h.defaultVlan ? `<div class="dp-row"><span class="dp-k">Default VLAN</span><span class="dp-v">${h.defaultVlan}</span></div>` : ''}
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">VMs on this host</div>
      <div class="dp-row"><span class="dp-k">Total</span><span class="dp-v">${vms.length}</span></div>
      <div class="dp-row"><span class="dp-k">Running</span><span class="dp-v" style="color:var(--green)">${run}</span></div>
    </div>
    <div class="dp-actions">
      <a href="https://${h.host}:8006" target="_blank" class="btn btn-g btn-fw" style="display:inline-flex;align-items:center;justify-content:center;gap:6px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg> Open Proxmox UI</a>
      ${canEdit ? `<button class="btn btn-g btn-fw" onclick="openModal('edit-host','${h.id}')" style="display:inline-flex;align-items:center;justify-content:center;gap:6px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg> Edit Host</button><div class="sep"></div><button class="btn btn-d btn-fw" onclick="delHost('${h.id}')" style="display:inline-flex;align-items:center;justify-content:center;gap:6px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg> Remove Host</button>` : ''}
    </div>`;
}

// ── Power Actions ─────────────────────────────────────────────────────────────
async function powerAction(vmId, action) {
  const labels = { start:'Starting', stop:'Stopping', reboot:'Rebooting', shutdown:'Shutting down' };
  toast(`${labels[action]||action}…`, false);
  try {
    await api('POST', `/api/vms/${vmId}/power`, { action });
    toast(`${action} command sent`, false);
    setTimeout(pollVmStatus, 3000);
  } catch(e) { toast(e.message); }
}

// ── Deploy ────────────────────────────────────────────────────────────────────
// ── Deploy org selector ────────────────────────────────────────────────────────
function populateDepOrgSel() {
  const sel = $('dep-org-sel'); if (!sel) return;
  const cur = sel.value;
  sel.innerHTML = '<option value="">- Select Organisation -</option>'
    + S.orgs.map(o=>`<option value="${o.id}">${o.name}</option>`).join('');
  if (cur && S.orgs.find(o=>o.id===cur)) sel.value = cur;
  else { sel.value = ''; S.deployOrgId = ''; }
}

function onDepOrgChange(orgId) {
  S.deployOrgId = orgId;
  const orgHosts = S.hosts.filter(h=>h.orgId===orgId);
  const orgVms   = S.vms.filter(v=>orgHosts.some(h=>h.id===v.hostId));
  const btn = $('dep-btn');
  btn.disabled = S.deploying || !orgId || !orgVms.length || !orgHosts.length;
  const org = S.orgs.find(o=>o.id===orgId);
  $('dep-sub').textContent = org
    ? `${org.name} · ${orgHosts.length} host${orgHosts.length!==1?'s':''} · ${orgVms.length} VM${orgVms.length!==1?'s':''}`
    : 'Select an organisation to deploy';
  renderDeploy();
}

function renderDeploy() {
  const orgId    = S.deployOrgId || '';
  const orgHosts = S.hosts.filter(h=>h.orgId===orgId);
  const orgVms   = S.vms.filter(v=>orgHosts.some(h=>h.id===v.hostId));
  const ordered  = ROLE_ORDER.flatMap(role => orgVms.filter(v=>v.role===role));

  $('q-ct').textContent = ordered.length + ' VMs';
  $('dep-steps').innerHTML = ordered.length ? ordered.map((v,i) => {
    const r=ROLES[v.role]||{}; const s=ST[v.status]||ST.pending;
    const cls=v.status==='running'?'done':['cloning','configuring'].includes(v.status)?'active':'pend';
    const tick=v.status==='running'?'✓':['cloning','configuring'].includes(v.status)?'...':(i+1);
    return `<div class="step ${cls}">
      <div class="step-dc">
        <div class="step-dot">${tick}</div>
        ${i<ordered.length-1?'<div class="step-line"></div>':''}
      </div>
      <div style="flex:1;padding-top:1px">
        <div class="step-name">${r.icon} ${v.hostname}</div>
        <div class="step-sub">${r.label} · ${v.ip}${v.vlan?` · VLAN${v.vlan}`:''}</div>
      </div>
      <span class="pill" style="background:${s.c}15;color:${s.c};align-self:flex-start;margin-top:2px">${s.l}</span>
    </div>`;
  }).join('') : `<div class="empty"><p>${orgId ? 'No VMs in this organisation' : 'Select an organisation above'}</p></div>`;

  $('role-order').innerHTML = ROLE_ORDER.map((role,i) => {
    const r=ROLES[role]||{}; const n=orgVms.filter(v=>v.role===role).length;
    return `<div style="display:flex;align-items:center;gap:7px;padding:5px 0;border-bottom:1px solid var(--b1)${i===ROLE_ORDER.length-1?';border:none':''}">
      <span style="font-family:var(--mono);font-size:9px;color:var(--text3);width:11px;text-align:right">${i+1}</span>
      <span style="font-size:11px">${r.icon}</span>
      <span style="font-size:11.5px;flex:1">${r.label}</span>
      ${n?`<span class="pill" style="background:${r.bg};color:${r.color}">${n}</span>`:`<span style="font-size:10px;color:var(--text3)">--</span>`}
    </div>`;
  }).join('');
}

let _pollInterval = null;

async function startDeploy() {
  if (S.deploying) return;
  const orgId = S.deployOrgId;
  if (!orgId) { toast('Select an organisation first'); return; }
  const orgHosts = S.hosts.filter(h=>h.orgId===orgId);
  const orgVms   = S.vms.filter(v=>orgHosts.some(h=>h.id===v.hostId));
  if (!orgHosts.length) { toast('No hosts in this organisation'); return; }
  if (!orgVms.length)   { toast('No VMs in this organisation'); return; }

  S.deploying = true; $('dep-btn').disabled = true;
  $('live-b').innerHTML = '<span style="font-size:10px;color:var(--amber);font-family:var(--mono);animation:blink .8s infinite">● STARTING</span>';
  $('log').textContent = '[windows-deployment] Sending deploy request...\n';
  try {
    const res = await api('POST', '/api/deploy', { orgId });
    if (!res.success) { toast(res.error||'Deploy failed'); stopDeploy(); return; }
  } catch(e) { toast(e.message); stopDeploy(); return; }
  $('live-b').innerHTML = '<span style="font-size:10px;color:var(--green);font-family:var(--mono);animation:blink .8s infinite">● LIVE</span>';
  $('deploy-status-bar').classList.add('visible');
  $('dsb-text').textContent = 'Deploy running...';
  $('abort-btn').style.display = '';
  orgVms.forEach(v => { v.status='cloning'; v.prog=0; });
  renderGrid(); renderTree(q());
  _pollInterval = setInterval(pollDeployStatus, 1500);
}

async function pollDeployStatus() {
  try {
    const data = await api('GET', '/api/deploy/status');
    const logDiv = $('log');
    if (data.log !== undefined) {
      logDiv.innerHTML = _fmtDeployLog(data.log);
      logDiv.scrollTop = logDiv.scrollHeight;
    }
    if (!data.running) {
      const failed = data.exitCode !== 0;
      if (failed) {
        logDiv.style.color = 'var(--red)'; logDiv.style.borderColor = 'var(--red)';
        $('live-b').innerHTML = `<span style="font-size:10px;color:var(--red);font-family:var(--mono)">&#x2717; FAILED (code ${data.exitCode})</span>`;
        $('dsb-text').textContent = 'Deploy failed';
        setTimeout(() => { logDiv.style.color=''; logDiv.style.borderColor=''; }, 5000);
      } else {
        $('live-b').innerHTML = '<span style="font-size:10px;color:var(--green);font-family:var(--mono)">&#x2713; Done</span>';
        $('dsb-text').textContent = 'Deploy finished';
      }
      stopDeploy(); loadHistory();
    } else {
      // Parse progress from log
      const prog = _parseDeployProgress(data.log||'');
      $('dsb-text').textContent = prog.label || 'Deploying...';
      const liveB = $('live-b');
      liveB.innerHTML = (prog.pct !== null
        ? `<span style="font-family:var(--mono);font-size:10px;color:var(--amber)">${prog.pct}%</span>`
        : '<span style="font-size:10px;color:var(--amber);font-family:var(--mono);animation:blink .8s infinite">&#x25cf; LIVE</span>') +
        (prog.label && prog.label !== 'Deploying...' ? `<span style="font-size:10px;color:var(--text3);max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${prog.label}">${prog.label}</span>` : '');
    }
  } catch(_) {}
}

// Parse Ansible output to extract progress percentage and current task label
function _parseDeployProgress(log) {
  const lines = log.split('\n').filter(l => l.trim());
  // Count PLAY and TASK lines for progress
  const plays = lines.filter(l => l.startsWith('PLAY [')).length;
  const tasks = lines.filter(l => l.startsWith('TASK [')).length;
  const totalTasks = 40; // rough estimate for full deploy
  const pct = Math.min(99, Math.round((tasks / totalTasks) * 100));
  // Current task/play label
  let label = 'Deploying...';
  for (let i = lines.length - 1; i >= 0; i--) {
    const l = lines[i];
    if (l.startsWith('TASK [')) {
      label = l.replace(/TASK \[/, '').replace(/\].*/, '').trim();
      if (label.length > 45) label = label.slice(0, 43) + '...';
      break;
    }
    if (l.startsWith('PLAY [')) {
      label = l.replace(/PLAY \[/, '').replace(/\].*/, '').trim();
      break;
    }
  }
  return { pct: tasks > 0 ? pct : null, label };
}

// Format raw Ansible log output with syntax highlighting
function _fmtDeployLog(raw) {
  const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  return raw.split('\n').map(line => {
    const l = esc(line);
    if (l.match(/^PLAY \[/))         return `<span class="lg-play">${l}</span>`;
    if (l.match(/^TASK \[/))         return `<span class="lg-task">${l}</span>`;
    if (l.match(/^ok:/))              return `<span class="lg-ok">${l}</span>`;
    if (l.match(/^changed:/))         return `<span class="lg-changed">${l}</span>`;
    if (l.match(/^fatal:|^failed:/i)) return `<span class="lg-fail">${l}</span>`;
    if (l.match(/^skipping:/))        return `<span class="lg-skip">${l}</span>`;
    if (l.match(/^PLAY RECAP/))       return `<span class="lg-recap">${l}</span>`;
    if (l.match(/^\[windows-deploy|^\[AD Setup/)) return `<span class="lg-play">${l}</span>`;
    if (l.match(/^\s*$/))            return '';
    if (l.match(/^PLAY \*{3}|^TASK \*{3}/)) return `<span class="lg-dim">${l}</span>`;
    return l;
  }).filter(l => l !== '').join('\n');
}


function stopDeploy() {
  S.deploying = false;
  $('dep-btn').disabled = !S.deployOrgId;
  $('abort-btn').style.display = 'none';
  clearInterval(_pollInterval);
  setTimeout(() => $('deploy-status-bar').classList.remove('visible'), 3000);
  setTimeout(pollVmStatus, 2000);
}

async function abortDeploy() {
  if (!S.deploying) return;
  if (!confirm('Abort deployment? All VMs created so far will be deleted from Proxmox.')) return;
  $('abort-btn').disabled = true;
  try {
    const data = await api('POST', '/api/deploy/abort', {});
    toast(data.cleaning?.length ? `Aborting -- deleting ${data.cleaning.length} VM(s)...` : 'Deploy aborted', false);
  } catch(e) { toast(e.message); }
  $('abort-btn').disabled = false;
  stopDeploy();
}

// ── Deploy History ─────────────────────────────────────────────────────────────
async function loadHistory() {
  try {
    const hist = await api('GET', '/api/deploy/history');
    const tbody = $('hist-body');
    if (!hist.length) { tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:16px;color:var(--text3)">No deploys yet</td></tr>'; return; }
    tbody.innerHTML = hist.map(h => {
      const start = new Date(h.startedAt);
      const dur = h.finishedAt ? Math.round((new Date(h.finishedAt)-start)/1000) + 's' : '--';
      const ok = h.exitCode === 0;
      return `<tr>
        <td style="font-family:var(--mono);font-size:11px">${start.toLocaleDateString()} ${start.toLocaleTimeString()}</td>
        <td>${h.startedBy||'--'}</td>
        <td>${h.orgName||h.orgId||'--'}</td>
        <td>${h.vmCount||'--'}</td>
        <td style="font-family:var(--mono)">${dur}</td>
        <td><span class="pill" style="background:${ok?'var(--green-d)':'var(--red-d)'};color:${ok?'var(--green)':'var(--red)'}">${ok?'✓ Success':'✗ Failed'}</span></td>
      </tr>`;
    }).join('');
  } catch(_) {}
}

// ── Admin: all active deploys overview ────────────────────────────────────────
let _adminDepInterval = null;
async function pollAdminDeploys() {
  if (S.session?.role !== 'admin') return;
  try {
    const all = await api('GET', '/api/deploy/all');
    const panel = $('admin-deploys-panel');
    const list  = $('admin-dep-list');
    const upd   = $('admin-dep-upd');
    if (!panel) return;
    panel.style.display = all.length ? '' : 'none';
    if (upd) upd.textContent = `Updated ${new Date().toLocaleTimeString()}`;
    list.innerHTML = all.map(d => {
      const started = d.startedAt ? new Date(d.startedAt).toLocaleTimeString() : '--';
      const statusColor = d.running ? 'var(--amber)' : d.exitCode===0 ? 'var(--green)' : 'var(--red)';
      const statusText  = d.running ? 'Running' : d.exitCode===0 ? 'Done' : 'Failed';
      return `<div style="padding:10px 13px;border-bottom:1px solid var(--b1)">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:6px">
          <div style="font-weight:600;font-size:12.5px;font-family:var(--mono)">${d.username}</div>
          <div style="font-size:11px;color:var(--text2)">${d.orgName||d.orgId||'--'}</div>
          <div style="font-size:10px;color:var(--text3);margin-left:auto">started ${started}</div>
          <span class="pill" style="background:${statusColor}18;color:${statusColor}">${statusText}</span>
          ${d.running?`<button class="btn btn-d btn-sm" style="padding:2px 8px;font-size:11px" onclick="adminAbortDeploy('${d.username}')">Abort</button>`:''}
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:5px">
          ${(d.vms||[]).map(v=>{const r=ROLES[v.role]||{};return`<span style="display:inline-flex;align-items:center;gap:4px;padding:2px 7px;background:var(--panel2);border:1px solid var(--b1);border-radius:var(--rad);font-size:11px;font-family:var(--mono)">${r.icon||'□'} ${v.hostname} <span style="color:var(--text3)">${v.ip}</span></span>`;}).join('')}
        </div>
        ${d.logTail?`<div style="margin-top:6px;font-size:10px;font-family:var(--mono);color:var(--text3);background:var(--panel2);padding:5px 7px;border-radius:var(--rad);max-height:60px;overflow:hidden;white-space:pre-wrap">${d.logTail.slice(-300)}</div>`:''}
      </div>`;
    }).join('');
  } catch(_) {}
}

async function adminAbortDeploy(username) {
  if (!confirm(`Abort ${username}'s deployment?`)) return;
  try { await api('POST','/api/deploy/abort-user',{username}); toast('Aborted',false); pollAdminDeploys(); }
  catch(e) { toast(e.message); }
}

// ── VM Status Polling ──────────────────────────────────────────────────────────
let _vmPollInterval = null;
function pveToStatus(pveStatus, uptime) {
  if (pveStatus==='running') return uptime>0 ? 'running' : 'configuring';
  if (pveStatus==='stopped') return 'stopped';
  return 'pending';
}
async function pollVmStatus() {
  if (!S.hosts.length || !S.vms.length) return;
  try {
    const statusMap = await api('GET', '/api/vms/proxmox-status');
    let changed = false;
    S.vms.forEach(v => {
      const pve = statusMap[v.hostname];
      if (!pve) { if (v.status!=='pending'&&v.status!=='cloning') { v.status='pending'; changed=true; } return; }
      const newStatus = pveToStatus(pve.status, pve.uptime);
      if (v.status!==newStatus||v.prog!==(pve.status==='running'?100:0)||v.vmid!==pve.vmid) {
        v.status=newStatus; v.prog=pve.status==='running'?100:0; v.vmid=pve.vmid; changed=true;
      }
    });
    if (changed) { renderGrid(); renderTree(q()); if (S.selVm && _vdTab==='resources') $('vd-content').innerHTML=_vdPaneResources(vb(S.selVm)); }
  } catch(_) {}
}
function startVmPolling() { clearInterval(_vmPollInterval); pollVmStatus(); _vmPollInterval = setInterval(pollVmStatus, 10000); }

// ── Templates ─────────────────────────────────────────────────────────────────
async function loadTemplates() {
  try {
    const templates = await api('GET', '/api/templates');
    const g = $('tmpl-grid');
    const canEdit = S.session?.role !== 'readonly';
    if (!templates.length) { g.innerHTML='<div class="empty"><p>No templates yet — save a deployment configuration as a template</p></div>'; return; }
    g.innerHTML = templates.map(t => `
      <div class="tmpl-card">
        <div class="tmpl-name">${t.name}${t.global?'&nbsp;<span class="pill" style="background:var(--amber-d);color:var(--amber)">global</span>':''}</div>
        <div class="tmpl-desc">${t.description||'No description'}</div>
        <div class="tmpl-meta">
          <span class="tmpl-m">${t.vms?.length||0} VMs</span>
          <span class="tmpl-m">·</span>
          <span class="tmpl-m">by ${t.owner}</span>
          <span class="tmpl-m">·</span>
          <span class="tmpl-m">${new Date(t.created).toLocaleDateString()}</span>
        </div>
        <div class="tmpl-actions">
          <button class="btn btn-a btn-sm" onclick="applyTemplate('${t.id}')" style="display:inline-flex;align-items:center;gap:4px"><svg width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'/></svg> Use</button>
          <button class="btn btn-g btn-sm" onclick="exportTemplate('${t.id}','${t.name}')" style="display:inline-flex;align-items:center;gap:4px"><svg width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4'/><polyline points='7 10 12 15 17 10'/><line x1='12' y1='15' x2='12' y2='3'/></svg> Export</button>
          ${canEdit&&(S.session?.role==='admin'||t.owner===S.session?.username)?`
            <button class="btn btn-g btn-sm" onclick="openModal('edit-template','${t.id}')" title='Edit' style='display:inline-flex;align-items:center;gap:3px'><svg width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7'/><path d='M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z'/></svg></button>
            <button class="btn btn-d btn-sm" onclick="delTemplate('${t.id}')" title='Delete' style='display:inline-flex;align-items:center;gap:3px'><svg width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='3 6 5 6 21 6'/><path d='M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6'/></svg></button>
          `:''}
        </div>
      </div>`).join('');
  } catch(e) { toast(e.message); }
}

async function applyTemplate(id) {
  const templates = await api('GET', '/api/templates');
  const t = templates.find(x => x.id===id); if (!t) return;
  if (!confirm(`Apply template "${t.name}"? This will replace all current VMs.`)) return;
  // Replace VMs with template VMs
  const c_vms = t.vms || [];
  // Remove all current VMs
  for (const v of [...S.vms]) { try { await api('DELETE', `/api/vms/${v.id}`); } catch(_) {} }
  S.vms = [];
  // Add template VMs
  for (const v of c_vms) {
    try { const r = await api('POST', '/api/vms', { ...v, status:'pending', prog:0 }); if (r.vm) S.vms.push(r.vm); } catch(_) {}
  }
  // Apply settings if template has them
  if (t.settings && Object.keys(t.settings).length) {
    Object.assign(S.settings, t.settings);
    await api('PUT', '/api/settings', S.settings);
    syncSettingsForm();
  }
  await loadState(); renderAll();
  toast(`Template "${t.name}" applied`, false);
  setView('overview', null);
}

async function delTemplate(id) {
  if (!confirm('Delete this template?')) return;
  try { await api('DELETE', `/api/templates/${id}`); loadTemplates(); } catch(e) { toast(e.message); }
}

function importTemplate() { $('file-import').click(); }
async function handleImport(input) {
  const file = input.files[0]; if (!file) return;
  const text = await file.text();
  let data; try { data = JSON.parse(text); } catch { toast('Invalid JSON file'); return; }
  try { await api('POST', '/api/templates/import', data); toast('Template imported', false); loadTemplates(); } catch(e) { toast(e.message); }
  input.value = '';
}

function saveCurrentAsTemplate() {
  openModal('new-template', null, true);
}

// ── Users (Admin) ──────────────────────────────────────────────────────────────
async function loadOrgs() {
  try {
    const orgs = await api('GET', '/api/organisations');
    S.orgs = orgs;
    const el = $('org-list');
    if (!el) return;
    if (!orgs.length) { el.innerHTML='<div style="padding:16px;text-align:center;color:var(--text3);font-size:12px">No organisations yet</div>'; return; }
    el.innerHTML = orgs.map(org => {
      const orgHosts = S.hosts.filter(h=>h.orgId===org.id);
      const d = org.defaults||{};
      return `<div style='padding:11px 13px;border-bottom:1px solid var(--b1);display:flex;align-items:center;gap:10px'>
        <span style="display:flex;align-items:center;justify-content:center;width:32px;height:32px;background:rgba(167,139,250,.1);border:1px solid rgba(167,139,250,.25);border-radius:6px;color:var(--purple)"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></span>
        <div style='flex:1'>
          <div style='font-weight:600;font-size:12.5px'>${org.name}</div>
          <div style='font-size:11px;color:var(--text2)'>${org.description||''}</div>
          <div style='font-size:10px;color:var(--text3);margin-top:2px'>${orgHosts.length} host${orgHosts.length!==1?'s':''} · ${d.gateway?'gw:'+d.gateway+' ':''} ${d.vlan?'vlan:'+d.vlan+' ':''} ${d.storage?d.storage:''}</div>
        </div>
        <button class='btn btn-g btn-sm' onclick='openModal("edit-org","${org.id}")' style='display:inline-flex;align-items:center;justify-content:center;gap:4px'><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg> Edit</button>
        <button class='btn btn-d btn-sm' onclick='delOrg("${org.id}")' title='Delete' style='display:inline-flex;align-items:center'><svg width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='3 6 5 6 21 6'/><path d='M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6'/></svg></button>
      </div>`;
    }).join('');
  } catch(e) { toast(e.message); }
}

async function loadUsers() {
  try {
    const users = await api('GET', '/api/users');
    const tbody = $('user-body');
    tbody.innerHTML = users.map(u => `<tr>
      <td style="font-family:var(--mono)">${u.username}</td>
      <td><span class="role-badge role-${u.role}">${u.role}</span></td>
      <td style="font-size:11px;color:var(--text3)">${u.added ? new Date(u.added).toLocaleDateString() : '—'}</td>
      <td style="text-align:right">
          <button class="btn btn-g btn-sm" onclick="openModal('edit-user','${u.username}')" title='Edit' style='display:inline-flex;align-items:center'><svg width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7'/><path d='M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z'/></svg></button>
        ${u.username!==S.session?.username ? `<button class="btn btn-d btn-sm" style="margin-left:4px;display:inline-flex;align-items:center" onclick="removeUser('${u.username}')" title="Remove"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg></button>` : ''}
      </td>
    </tr>`).join('');
  } catch(e) { toast(e.message); }
}

// changeRole removed — use saveEditUser instead
async function removeUser(username) {
  if (!confirm(`Remove user ${username}?`)) return;
  try { await api('DELETE', `/api/users/${username}`); loadUsers(); } catch(e) { toast(e.message); }
}

// ── Settings ───────────────────────────────────────────────────────────────────
function syncSettingsForm() {
  const s = S.settings;
  $('s-net').value = s.net||'172.16.10'; $('s-gw').value = s.gw||'172.16.10.1'; $('s-pfx').value = s.pfx||24;
  $('s-dns1').value = s.dns1||'8.8.8.8'; $('s-dns2').value = s.dns2||'1.1.1.1';
  $('s-vlan').value = s.vlan||''; $('s-cpus').value = s.cpus||2; $('s-ram').value = s.ram||4096;
  $('s-disk').value = s.disk||75; $('s-pass').value = s.pass||'Asdf1234!';
  $('s-tz').value = s.tz||'W. Europe Standard Time'; $('s-locale').value = s.locale||'de-CH';
}
async function saveSettings() {
  S.settings = { ...S.settings,
    cpus: +($('s-cpus')?.value)||2, ram: +($('s-ram')?.value)||4096,
    disk: +($('s-disk')?.value)||75,
    tz: $('s-tz')?.value||'W. Europe Standard Time',
    locale: $('s-locale')?.value||'de-CH' };
  try {
    await api('PUT', '/api/settings', S.settings);
    const btn=$('save-btn'); btn.textContent='✓ Saved'; btn.style.background='var(--green)'; btn.style.color='#000';
    setTimeout(() => { btn.textContent='Save'; btn.style.background=''; btn.style.color=''; }, 1600);
  } catch(e) { toast(e.message); }
}

// ── Modals ─────────────────────────────────────────────────────────────────────
function openModal(type, id, fromCurrentConfig) {
  $('modal-bg').classList.add('open');
  const s = S.settings;
  const canAdmin = S.session?.role === 'admin';

  if (type==='new-org') {
    $('modal-title').textContent = 'New Organisation';
    $('modal-body').innerHTML = `
      <div class='ff'><label>Organisation Name</label><input id='org-name' autocomplete='off' placeholder='Contoso Ltd.'></div>
      <div class='ff'><label>Description</label><input id='org-desc' autocomplete='off' placeholder='Main office infrastructure'></div>
      ${orgDefaultsForm()}`;
    $('modal-foot').innerHTML = `<button class='btn btn-g' onclick='closeModal()'>Cancel</button><button class='btn btn-a' onclick='saveNewOrg()'>Create</button>`;
    return;
  }

  if (type==='edit-org') {
    const org = ob(id); if (!org) return;
    $('modal-title').textContent = 'Edit Organisation — '+org.name;
    $('modal-body').innerHTML = `
      <div class='ff'><label>Organisation Name</label><input id='org-name' autocomplete='off' value='${org.name}'></div>
      <div class='ff'><label>Description</label><input id='org-desc' autocomplete='off' value='${org.description||''}'></div>
      ${orgDefaultsForm(org.defaults)}`;
    $('modal-foot').innerHTML = `<button class='btn btn-g' onclick='closeModal()'>Cancel</button><button class='btn btn-a' onclick='saveEditOrg("${id}")'>Save</button>`;
    return;
  }

  if (type==='add-host-to-org') {
    // id = orgId, reuse host modal but pre-set orgId
    const org = ob(id); if (!org) return;
    $('modal-title').textContent = `Add Host to ${org.name}`;
    const d = org.defaults || {};
    $('modal-body').innerHTML = `
      <div class='ff'><label>Display Name</label><input id='m-name' autocomplete='off' placeholder='pve-main'></div>
      <div class='g2'>
        <div class='ff'><label>Host IP / FQDN</label><input id='m-host' autocomplete='off' placeholder='172.16.10.2'></div>
        <div class='ff'><label>Node Name</label><input id='m-node' autocomplete='off' value='pve'></div>
      </div>
      <div class='ff'><label>API Token ID</label><input id='m-tokid' autocomplete='off' placeholder='root@pam!deployment-token'></div>
      <div class='ff'><label>API Token Secret</label><input type='text' id='m-toksec' autocomplete='off' data-1p-ignore data-lpignore='true' style='font-family:var(--mono);font-size:11.5px'></div>
      <div class='ff'><label>Template VM Name</label><input id='m-tmpl' autocomplete='off' value='${d.templateName||'win2025-template'}'></div>
      <div class='g2'>
        <div class='ff'><label>Storage Pool</label><input id='m-stor' autocomplete='off' value='${d.storage||'local-lvm'}'></div>
        <div class='ff'><label>Network Bridge</label><input id='m-bridge' autocomplete='off' value='${d.bridge||'vmbr0'}'></div>
      </div>
      <div class='ff'><label>Default VLAN</label><input id='m-dvlan' autocomplete='off' value='${d.vlan||''}'></div>`;
    $('modal-foot').innerHTML = `<button class='btn btn-g' onclick='closeModal()'>Cancel</button><button class='btn btn-a' onclick='saveHostToOrg("${id}")'>Add Host</button>`;
    return;
  }

  if (type==='user-menu') {
    $('modal-title').textContent = S.session?.username||'';
    $('modal-body').innerHTML = `<p style="font-size:12px;color:var(--text2);margin-bottom:12px">Signed in as <strong>${S.session?.username}</strong> (${S.session?.role})</p>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" style="display:inline-flex;align-items:center;gap:6px" onclick="closeModal();openModal('change-password')"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg> Change Password</button><button class="btn btn-d" style="display:inline-flex;align-items:center;gap:6px" onclick="doLogout()"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg> Sign out</button>`;
    return;
  }

  if (type==='add-user') {
    $('modal-title').textContent = 'Add User';
    $('modal-body').innerHTML = `
      <div class="ff"><label>Username</label><input id="m-uname" autocomplete="off" placeholder="alice"></div>
      <div class="ff"><label>Password</label><input type="password" id="m-upw" autocomplete="new-password" placeholder="Min. 8 characters"></div>
      <div class="ff"><label>Confirm Password</label><input type="password" id="m-upw2" autocomplete="new-password" placeholder="Repeat password"></div>
      <div class="ff"><label>Role</label><select id="m-urole">
        <option value="readonly">readonly \u2014 view only</option>
        <option value="deploy" selected>deploy \u2014 manage VMs and deploy</option>
        <option value="admin">admin \u2014 full access</option>
      </select></div>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="addUser()">Create User</button>`;
    return;
  }

  if (type==='edit-user') {
    api('GET','/api/users').then(users => {
      const u = users.find(x=>x.username===id); if (!u) return;
      const isSelf = u.username === S.session?.username;
      $('modal-title').textContent = 'Edit User \u2014 '+u.username;
      $('modal-body').innerHTML = `
        <div class="ff"><label>Role</label><select id="e-urole"${isSelf?' disabled':''}>
          <option value="readonly"${u.role==='readonly'?' selected':''}>readonly \u2014 view only</option>
          <option value="deploy"${u.role==='deploy'?' selected':''}>deploy \u2014 manage VMs and deploy</option>
          <option value="admin"${u.role==='admin'?' selected':''}>admin \u2014 full access</option>
        </select></div>${isSelf?'<p style="font-size:11px;color:var(--text3)">You cannot change your own role.</p>':''}
        <div style="margin-top:12px;padding-top:10px;border-top:1px solid var(--b1)">
          <div style="font-size:10px;color:var(--text3);text-transform:uppercase;letter-spacing:.08em;margin-bottom:8px">Reset Password (optional)</div>
          <div class="ff"><label>New Password</label><input type="password" id="e-upw" autocomplete="new-password" placeholder="Leave blank to keep current"></div>
          <div class="ff"><label>Confirm</label><input type="password" id="e-upw2" autocomplete="new-password" placeholder="Repeat new password"></div>
        </div>`;
      $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveEditUser('${id}')" >Save</button>`;
    });
    return;
  }

  if (type==='change-password') {
    $('modal-title').textContent = 'Change Password';
    $('modal-body').innerHTML = `
      <div class="ff"><label>Current Password</label><input type="password" id="cp-cur" autocomplete="current-password"></div>
      <div class="ff"><label>New Password</label><input type="password" id="cp-new" autocomplete="new-password" placeholder="Min. 8 characters"></div>
      <div class="ff"><label>Confirm New Password</label><input type="password" id="cp-new2" autocomplete="new-password"></div>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="changePassword()">Change Password</button>`;
    return;
  }

  if (type==='host') {
    $('modal-title').textContent = 'Add Proxmox Host';
    if (!S.orgs.length) {
      $('modal-body').innerHTML = `
        <div style="text-align:center;padding:20px 0;color:var(--text2)">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin-bottom:10px;opacity:.5"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          <div style="font-size:13px;font-weight:600;margin-bottom:6px">No organisations yet</div>
          <div style="font-size:12px;color:var(--text3)">Create an organisation first. Hosts must belong to an organisation so their network defaults and credentials are properly configured.</div>
        </div>`;
      $('modal-foot').innerHTML = '<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="closeModal();openModal(\'new-org\')">Create Organisation</button>';
      return;
    }
    const _firstOd = S.orgs[0]?.defaults || {};
    window._hostOrgChanged = (orgId) => {
      const d = S.orgs.find(o=>o.id===orgId)?.defaults || {};
      if ($('m-stor'))   $('m-stor').value   = d.storage      || 'local-lvm';
      if ($('m-bridge')) $('m-bridge').value = d.bridge       || 'vmbr0';
      if ($('m-dvlan'))  $('m-dvlan').value  = d.vlan         || '';
      if ($('m-tmpl'))   $('m-tmpl').value   = d.templateName || '';
    };
    $('modal-body').innerHTML =
      '<div class="ff"><label>Organisation</label><select id="m-org-id" onchange="_hostOrgChanged(this.value)">'
      + S.orgs.map(o=>'<option value="'+o.id+'">'+o.name+'</option>').join('')
      + '</select></div>'
      + ''
      + '<div class="g2"><div class="ff"><label>Host IP / FQDN</label><input id="m-host" autocomplete="off" placeholder="172.16.10.2"></div>'
      + '<div class="ff"><label>Node Name</label><input id="m-node" autocomplete="off" value="pve"></div></div>'
      + '<div class="ff"><label>API Token ID</label><input id="m-tokid" autocomplete="off" placeholder="root@pam!deployment-token"></div>'
      + '<div class="ff"><label>API Token Secret</label><input type="text" id="m-toksec" autocomplete="off" data-1p-ignore data-lpignore="true" style="font-family:var(--mono);font-size:11.5px"></div>'
      + '<div class="ff"><label>Template VM Name</label><input id="m-tmpl" autocomplete="off" placeholder="'+(_firstOd.templateName||'win2025-template')+'"></div>'
      + '<div class="g2"><div class="ff"><label>Storage Pool</label><input id="m-stor" autocomplete="off" value="'+(_firstOd.storage||'local-lvm')+'"></div>'
      + '<div class="ff"><label>Network Bridge</label><input id="m-bridge" autocomplete="off" value="'+(_firstOd.bridge||'vmbr0')+'"></div></div>'
      + '<div class="ff"><label>Default VLAN</label><input id="m-dvlan" autocomplete="off" value="'+(_firstOd.vlan||'')+'" placeholder="from org"></div>';
    $('modal-foot').innerHTML =
      '<button class="btn btn-g" onclick="closeModal()">Cancel</button>'
      + '<button class="btn btn-a" onclick="saveHost()">Save Host</button>';
    // Trigger defaults for first org
    if (S.orgs[0]?.id) setTimeout(() => window._hostOrgChanged?.(S.orgs[0].id), 0);
    return;
  }

  if (type==='edit-host') {
    const h=hb(id); if (!h) return;
    $('modal-title').textContent = 'Edit Host — '+h.name;
    $('modal-body').innerHTML = `
      <div class="g2">
        <div class="ff"><label>Host IP / FQDN</label><input id="m-host" autocomplete="off" value="${h.host}"></div>
        <div class="ff"><label>Node Name</label><input id="m-node" autocomplete="off" value="${h.node}"></div>
      </div>
      <div class="ff"><label>API Token ID</label><input id="m-tokid" autocomplete="off" value="${h.tokenId}"></div>
      <div class="ff"><label>API Token Secret</label><input type="text" id="m-toksec" autocomplete="off" data-1p-ignore data-lpignore="true" placeholder="Leave blank to keep current" style="font-family:var(--mono);font-size:11.5px"></div>
      <div class="ff"><label>Template VM Name</label><input id="m-tmpl" autocomplete="off" value="${h.templateName||''}"></div>
      <div class="g2">
        <div class="ff"><label>Storage Pool</label><input id="m-stor" autocomplete="off" value="${h.storage}"></div>
        <div class="ff"><label>Network Bridge</label><input id="m-bridge" autocomplete="off" value="${h.bridge}"></div>
      </div>
      <div class="ff"><label>Default VLAN (optional)</label><input id="m-dvlan" autocomplete="off" value="${h.defaultVlan||''}"></div>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveEditHost('${id}')">Save</button>`;
    return;
  }

  if (type==='vm') {
    // Require at least one organisation
    if (!S.orgs.length) {
      $('modal-title').textContent = 'Add VM';
      $('modal-body').innerHTML = `
        <div style="text-align:center;padding:20px 0;color:var(--text2)">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin-bottom:10px;opacity:.5"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          <div style="font-size:13px;font-weight:600;margin-bottom:6px">No organisations yet</div>
          <div style="font-size:12px;color:var(--text3)">Create an organisation first. VMs inherit network settings, credentials and defaults from their organisation.</div>
        </div>`;
      $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="closeModal();openModal('new-org')">Create Organisation</button>`;
      return;
    }

    const defRole = ROLES['dc'];
    const s = S.settings;

    // Helper: when org changes, update host list + prefill defaults
    window._vmOrgChanged = (orgId) => {
      const org = S.orgs.find(o => o.id === orgId);
      const od  = org?.defaults || {};
      const orgHosts = S.hosts.filter(h => h.orgId === orgId);

      // Rebuild host selector
      const hsel = $('m-hid');
      hsel.innerHTML = orgHosts.length
        ? orgHosts.map(h => `<option value="${h.id}">${h.name} (${h.host})</option>`).join('')
        : '<option value="">— No hosts in this organisation —</option>';

      // Prefill defaults from org (only if field is still at default/empty)
      if (od.vlan)   { const f=$('m-vlan');      if (!f.dataset.touched) f.placeholder=od.vlan; }
      if (od.bridge) { const f=$('m-bridge-vm'); if (!f.dataset.touched) f.placeholder=od.bridge; }
      if (od.domain) { const f=$('m-domain');    if (f && !f.dataset.touched) f.placeholder=od.domain; }
      // IP placeholder
      const netPfx = od.netPrefix || '';
      const ipf = $('m-ip');
      if (netPfx && !ipf.dataset.touched) ipf.placeholder = netPfx + '.10';
    };

    $('modal-title').textContent = 'Add VM';
    $('modal-body').innerHTML = `
      <div class="ff"><label>Organisation</label>
        <select id="m-org-sel" onchange="window._vmOrgChanged(this.value)">
          ${S.orgs.map(o=>`<option value="${o.id}">${o.name}</option>`).join('')}
        </select>
      </div>
      <div class="ff"><label>Host</label>
        <select id="m-hid"></select>
      </div>
      <div class="ff"><label>Role</label>
        <select id="m-role" onchange="applyRoleDef(this.value)">
          ${Object.entries(ROLES).map(([k,v])=>`<option value="${k}">${v.icon}  ${v.label}</option>`).join('')}
        </select>
      </div>
      <div class="g2">
        <div class="ff"><label>Hostname</label><input id="m-hn" autocomplete="off" placeholder="dc01"></div>
        <div class="ff"><label>IP Address</label><input id="m-ip" autocomplete="off" placeholder="172.16.10.10" oninput="this.dataset.touched='1'"></div>
      </div>
      <div class="g3">
        <div class="ff"><label>CPUs</label><input type="number" id="m-cpus" autocomplete="off" value="${defRole.dcpu}"></div>
        <div class="ff"><label>RAM (MB)</label><input type="number" id="m-ram" autocomplete="off" value="${defRole.dram}" step="1024"></div>
        <div class="ff"><label>Disk (GB)</label><input type="number" id="m-disk" autocomplete="off" value="${s.disk}"></div>
      </div>
      <div class="g2">
        <div class="ff"><label>VLAN override</label><input id="m-vlan" autocomplete="off" placeholder="from org" oninput="this.dataset.touched='1'"></div>
        <div class="ff"><label>Bridge override</label><input id="m-bridge-vm" autocomplete="off" placeholder="from org" oninput="this.dataset.touched='1'"></div>
        <div class="ff"><label>Domain (leave blank for org default)</label><input id="m-domain" autocomplete="off" placeholder="from org" oninput="this.dataset.touched='1'"></div>
      </div>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveVm()">+ Add VM</button>`;
    // Trigger org change to populate hosts + defaults
    setTimeout(() => window._vmOrgChanged(S.orgs[0]?.id), 0);
    return;
  }

  if (type==='edit-vm') {
    const v=vb(id); if (!v) return;
    $('modal-title').textContent = 'Edit — '+v.hostname;
    $('modal-body').innerHTML = `
      <div class="ff"><label>Role</label><select id="e-role">${Object.entries(ROLES).map(([k,r])=>`<option value="${k}"${k===v.role?' selected':''}>${r.icon}  ${r.label}</option>`).join('')}</select></div>
      <div class="g2">
        <div class="ff"><label>Hostname</label><input id="e-hn" autocomplete="off" value="${v.hostname}"></div>
        <div class="ff"><label>IP Address</label><input id="e-ip" autocomplete="off" value="${v.ip}"></div>
      </div>
      <div class="g3">
        <div class="ff"><label>CPUs</label><input type="number" id="e-cpus" autocomplete="off" value="${v.cpus}"></div>
        <div class="ff"><label>RAM (MB)</label><input type="number" id="e-ram" autocomplete="off" value="${v.ram}" step="1024"></div>
        <div class="ff"><label>Disk (GB)</label><input type="number" id="e-disk" autocomplete="off" value="${v.disk}"></div>
      </div>
      <div class="g2">
        <div class="ff"><label>VLAN</label><input id="e-vlan" autocomplete="off" value="${v.vlan||''}"></div>
        <div class="ff"><label>Bridge</label><input id="e-bridge" autocomplete="off" value="${v.bridge||''}"></div>
      </div>
      ${S.hosts.length>1?`<div class="ff"><label>Host</label><select id="e-hid">${S.hosts.map(h=>`<option value="${h.id}"${h.id===v.hostId?' selected':''}>${h.name}</option>`).join('')}</select></div>`:''}`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveEditVm('${id}')">Save</button>`;
    return;
  }

  if (type==='new-template'||type==='edit-template') {
    const isEdit = type==='edit-template';
    $('modal-title').textContent = isEdit ? 'Edit Template' : 'New Template';
    $('modal').style.maxWidth = '580px';
    // Independent VM list — not linked to S.vms
    window._tmplVms = [];
    const renderTmplVmList = () => {
      const el = $('tmpl-vm-list'); if (!el) return;
      el.innerHTML = window._tmplVms.length
        ? window._tmplVms.map((v,i) => `
            <div style="display:flex;align-items:center;gap:7px;padding:5px 0;border-bottom:1px solid var(--b1)">
              <span style="font-size:13px;width:18px">${ROLES[v.role]?.icon||"□"}</span>
              <span style="font-family:var(--mono);font-size:11.5px;flex:1">${v.hostname}</span>
              <span style="font-size:11px;color:var(--text3);font-family:var(--mono)">${v.ip}</span>
              <span style="font-size:10px;color:var(--text2);min-width:90px">${ROLES[v.role]?.label||v.role}</span>
              <button class="btn btn-d btn-sm" style="padding:2px 7px" onclick="_tmplRemove(${i})"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
            </div>`).join('')
        : '<div style="color:var(--text3);font-size:12px;padding:8px 0">No VMs — add some below</div>';
    };
    window._tmplRemove = (i) => { window._tmplVms.splice(i,1); renderTmplVmList(); };
    window._tmplAdd = () => {
      const hn=($('tadd-hn').value||'').trim(), ip=($('tadd-ip').value||'').trim(), role=$('tadd-role').value;
      if (!hn||!ip) { toast('Hostname and IP required'); return; }
      window._tmplVms.push({ hostname:hn, ip, role, cpus:2, ram:4096, disk:75, vlan:'', bridge:'' });
      renderTmplVmList();
      $('tadd-hn').value=''; $('tadd-ip').value='';
    };
    const roleOpts = Object.entries(ROLES).map(([k,r])=>`<option value="${k}">${r.icon} ${r.label}</option>`).join('');
    $('modal-body').innerHTML = `
      <div class="ff"><label>Template Name</label><input id="tmpl-name" autocomplete="off" placeholder="Standard DC + File Server"></div>
      <div class="ff"><label>Description</label><textarea id="tmpl-desc" rows="2" placeholder="What does this deployment include?"></textarea></div>
      ${canAdmin ? `<div style="display:flex;align-items:center;gap:8px;margin-bottom:10px"><input type="checkbox" id="tmpl-global" ${!isEdit?'checked':''}><label style="font-size:12px;color:var(--text2);margin-bottom:0">Global — visible to all users</label></div>` : ''}
      <div style="font-size:9px;color:var(--text3);text-transform:uppercase;letter-spacing:.08em;margin-bottom:6px;font-weight:600;margin-top:4px">VMs in this template</div>
      <div id="tmpl-vm-list" style="margin-bottom:10px;min-height:32px"></div>
      <div style="background:var(--panel2);border:1px solid var(--b1);border-radius:var(--rad);padding:10px">
        <div style="font-size:9px;color:var(--text3);text-transform:uppercase;letter-spacing:.08em;margin-bottom:8px;font-weight:600">Add VM</div>
        <div class="g2" style="margin-bottom:6px">
          <div class="ff" style="margin-bottom:0"><label>Hostname</label><input id="tadd-hn" autocomplete="off" placeholder="dc01"></div>
          <div class="ff" style="margin-bottom:0"><label>IP Address</label><input id="tadd-ip" autocomplete="off" placeholder="172.16.10.11"></div>
        </div>
        <div class="ff" style="margin-bottom:8px"><label>Role</label><select id="tadd-role">${roleOpts}</select></div>
        <button class="btn btn-g btn-fw" onclick="_tmplAdd()" style="display:inline-flex;align-items:center;justify-content:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> Add VM to template</button>
      </div>`;
    renderTmplVmList();
    if (isEdit) {
      api('GET','/api/templates').then(templates => {
        const t = templates.find(x=>x.id===id); if (!t) return;
        $('tmpl-name').value = t.name;
        $('tmpl-desc').value = t.description||'';
        if ($('tmpl-global')) $('tmpl-global').checked = !!t.global;
        window._tmplVms = JSON.parse(JSON.stringify(t.vms||[]));
        renderTmplVmList();
      });
    }
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal();$('modal').style.maxWidth=''">Cancel</button><button class="btn btn-a" onclick="${isEdit?`saveEditTemplate('${id}')`:'saveNewTemplate()'}">Save Template</button>`;
    return;
  }
}

async function addUser() {
  const username = $('m-uname').value.trim();
  const password = $('m-upw').value;
  const password2 = $('m-upw2').value;
  const role = $('m-urole').value;
  if (!username) { toast('Username required'); return; }
  if (!password) { toast('Password required'); return; }
  if (password !== password2) { toast('Passwords do not match'); return; }
  try { await api('POST', '/api/users', { username, password, role }); closeModal(); loadUsers(); toast('User created', false); } catch(e) { toast(e.message); }
}

async function saveEditUser(username) {
  const role = $('e-urole')?.value;
  const pw = $('e-upw')?.value;
  const pw2 = $('e-upw2')?.value;
  if (pw && pw !== pw2) { toast('Passwords do not match'); return; }
  const body = {};
  if (role) body.role = role;
  if (pw) body.password = pw;
  try { await api('PUT', `/api/users/${username}`, body); closeModal(); loadUsers(); toast('User updated', false); } catch(e) { toast(e.message); }
}

async function changePassword() {
  const cur = $('cp-cur').value, nw = $('cp-new').value, nw2 = $('cp-new2').value;
  if (!cur || !nw) { toast('All fields required'); return; }
  if (nw !== nw2) { toast('New passwords do not match'); return; }
  try { await api('POST', '/api/auth/change-password', { currentPassword: cur, newPassword: nw }); closeModal(); toast('Password changed', false); } catch(e) { toast(e.message); }
}

async function saveHostToOrg(orgId) {
  const h=($('m-host').value||'').trim();
  if (!h) { toast('Host IP required'); return; }
  const newHost = {
    name:n, host:h, node:$('m-node').value||'pve',
    tokenId:$('m-tokid').value, tokenSecret:$('m-toksec').value,
    templateName:$('m-tmpl').value||'win2025-template',
    storage:$('m-stor').value||'local-lvm', bridge:$('m-bridge').value||'vmbr0',
    defaultVlan:$('m-dvlan').value||'', orgId
  };
  try {
    await api('POST','/api/hosts',newHost);
    await loadState(); closeDetail(); closeModal(); renderAll();
    toast('Host added to organisation',false);
  } catch(e) { toast(e.message); }
}

function applyRoleDef(role) {
  const r=ROLES[role]||{};
  if (r.dcpu) $('m-cpus').value=r.dcpu;
  if (r.dram) $('m-ram').value=r.dram;
}

async function saveHost() {
  const h=($('m-host').value||'').trim();
  if (!h) { toast('Host IP required'); return; }
  const _hostOrgId = $('m-org-id')?.value||'';
  if (!_hostOrgId) { toast('Select an organisation'); return; }
  const node = $('m-node').value||'pve';
  const newHost = { name:node, host:h, node, tokenId:$('m-tokid').value,
    tokenSecret:$('m-toksec').value, templateName:$('m-tmpl').value||'win2025-template',
    storage:$('m-stor').value||'local-lvm', bridge:$('m-bridge').value||'vmbr0',
    defaultVlan:$('m-dvlan').value||'', orgId:_hostOrgId };
  try { await api('POST','/api/hosts',newHost); await loadState(); closeModal(); renderAll(); toast('Host added',false); } catch(e) { toast(e.message); }
}

async function saveEditHost(id) {
  const h=hb(id); if (!h) return;
  const update = { name:$('m-node').value||h.node, host:$('m-host').value||h.host,
    node:$('m-node').value||h.node, tokenId:$('m-tokid').value||h.tokenId,
    templateName:$('m-tmpl').value||h.templateName, storage:$('m-stor').value||h.storage,
    bridge:$('m-bridge').value||h.bridge, defaultVlan:$('m-dvlan').value||'' };
  const secret=$('m-toksec').value; if (secret) update.tokenSecret=secret;
  try { await api('PUT',`/api/hosts/${id}`,update); await loadState(); closeModal(); renderAll(); if (S.selHost===id) showHostDetail(id); toast('Host updated',false); } catch(e) { toast(e.message); }
}

async function saveVm() {
  const hn=($('m-hn').value||'').trim(), ip=($('m-ip').value||'').trim();
  if (!hn||!ip) { toast('Hostname and IP required'); return; }
  const hostId = $('m-hid')?.value;
  if (!hostId) { toast('Select a host — add hosts to this organisation first'); return; }
  const orgId  = $('m-org-sel')?.value || '';
  const vm = { hostId, orgId, role:$('m-role').value, hostname:hn, name:hn, ip,
    cpus:+$('m-cpus').value||S.settings.cpus, ram:+$('m-ram').value||S.settings.ram,
    disk:+$('m-disk').value||S.settings.disk, vlan:$('m-vlan').value||'',
    bridge:$('m-bridge-vm').value||'', domain:$('m-domain')?.value||'', status:'pending', prog:0 };
  try { await api('POST','/api/vms',vm); await loadState(); closeModal(); renderAll(); } catch(e) { toast(e.message); }
}

async function saveEditVm(id) {
  const v=vb(id); if (!v) return;
  v.role=$('e-role').value; v.hostname=$('e-hn').value||v.hostname; v.name=v.hostname;
  v.ip=$('e-ip').value||v.ip; v.cpus=+$('e-cpus').value||v.cpus; v.ram=+$('e-ram').value||v.ram;
  v.disk=+$('e-disk').value||v.disk; v.vlan=$('e-vlan').value||''; v.bridge=$('e-bridge').value||'';
  if ($('e-hid')) v.hostId=$('e-hid').value;
  try { await api('PUT',`/api/vms/${id}`,v); closeModal(); renderAll(); showVmDetail(id); } catch(e) { toast(e.message); }
}

async function delVm(id) {
  if (!confirm('Remove VM? This does not delete it from Proxmox.')) return;
  try { await api('DELETE',`/api/vms/${id}`); S.vms=S.vms.filter(v=>v.id!==id); closeDetail(); renderAll(); } catch(e) { toast(e.message); }
}
async function delHost(id) {
  if (!confirm('Remove host and all its VM definitions?')) return;
  try { await api('DELETE',`/api/hosts/${id}`); S.hosts=S.hosts.filter(h=>h.id!==id); S.vms=S.vms.filter(v=>v.hostId!==id); closeDetail(); renderAll(); } catch(e) { toast(e.message); }
}

async function saveNewTemplate() {
  const name=($('tmpl-name').value||'').trim();
  if (!name) { toast('Name required'); return; }
  const isGlobal = $('tmpl-global')?.checked ?? false;
  try {
    await api('POST','/api/templates',{ name, description:$('tmpl-desc').value, vms:window._tmplVms||[], settings:S.settings, global:isGlobal });
    closeModal(); toast('Template saved',false); if (S.view==='templates') loadTemplates();
  } catch(e) { toast(e.message); }
}

async function saveEditTemplate(id) {
  const name=($('tmpl-name').value||'').trim();
  if (!name) { toast('Name required'); return; }
  try {
    await api('PUT',`/api/templates/${id}`,{ name, description:$('tmpl-desc').value, global:$('tmpl-global')?.checked??false, vms:window._tmplVms||[] });
    closeModal(); loadTemplates(); toast('Template updated',false);
  } catch(e) { toast(e.message); }
}

// ── Org CRUD ─────────────────────────────────────────────────────────────────
async function saveNewOrg() {
  const name = ($('org-name').value||'').trim();
  if (!name) { toast('Name required'); return; }
  const defaults = {
    gateway: $('org-gw').value||'', pfx: $('org-pfx').value||'',
    netPrefix: $('org-netpfx').value||'', dns1: $('org-dns1').value||'', dns2: $('org-dns2').value||'',
    vlan: $('org-vlan').value||'', bridge: $('org-bridge').value||'',
    storage: $('org-storage').value||'', templateName: $('org-tmpl').value||'',
    pass: $('org-pass').value||'',
    domain: $('org-domain')?.value||'',
  };
  try {
    const r = await api('POST','/api/organisations',{ name, description:$('org-desc').value, defaults });
    if (r.org) S.orgs.push(r.org);
    else { const orgs = await api('GET','/api/organisations'); S.orgs = orgs; }
    closeModal(); renderAll(); toast('Organisation created',false);
  } catch(e) { toast(e.message); }
}

async function saveEditOrg(id) {
  const name = ($('org-name').value||'').trim();
  if (!name) { toast('Name required'); return; }
  const defaults = {
    gateway: $('org-gw').value||'', pfx: $('org-pfx').value||'',
    netPrefix: $('org-netpfx').value||'', dns1: $('org-dns1').value||'', dns2: $('org-dns2').value||'',
    vlan: $('org-vlan').value||'', bridge: $('org-bridge').value||'',
    storage: $('org-storage').value||'', templateName: $('org-tmpl').value||'',
    pass: $('org-pass').value||'',
    domain: $('org-domain')?.value||'',
  };
  try {
    await api('PUT',`/api/organisations/${id}`,{ name, description:$('org-desc').value, defaults });
    const orgs = await api('GET','/api/organisations'); S.orgs = orgs;
    closeModal(); renderAll(); if (S.selOrg===id) showOrgDetail(id); toast('Organisation updated',false);
  } catch(e) { toast(e.message); }
}

async function delOrg(id) {
  const org = ob(id);
  const orgHosts = S.hosts.filter(h=>h.orgId===id);
  const msg = orgHosts.length
    ? `Delete organisation "${org?.name}"? ${orgHosts.length} host(s) will be unassigned.`
    : `Delete organisation "${org?.name}"?`;
  if (!confirm(msg)) return;
  try {
    await api('DELETE',`/api/organisations/${id}`);
    S.orgs = S.orgs.filter(o=>o.id!==id);
    S.hosts.forEach(h => { if (h.orgId===id) h.orgId=''; });
    closeDetail(); renderAll(); toast('Organisation deleted',false);
  } catch(e) { toast(e.message); }
}

function orgDefaultsForm(d) {
  d = d || {};
  return `
    <div style='margin-top:12px;padding-top:10px;border-top:1px solid var(--b1)'>
    <div style='font-size:10px;color:var(--text3);text-transform:uppercase;letter-spacing:.08em;margin-bottom:8px;font-weight:600'>Organisation Defaults</div>
    <div class='g2'>
      <div class='ff'><label>Gateway</label><input id='org-gw' autocomplete='off' value='${d.gateway||""}' placeholder='172.16.10.1'></div>
      <div class='ff'><label>Network prefix</label><input id='org-netpfx' autocomplete='off' value='${d.netPrefix||""}' placeholder='172.16.10'></div>
    </div>
    <div class='g3'>
      <div class='ff'><label>Subnet</label><input id='org-pfx' autocomplete='off' value='${d.pfx||""}' placeholder='24'></div>
      <div class='ff'><label>Primary DNS</label><input id='org-dns1' autocomplete='off' value='${d.dns1||""}' placeholder='8.8.8.8'></div>
      <div class='ff'><label>Secondary DNS</label><input id='org-dns2' autocomplete='off' value='${d.dns2||""}' placeholder='1.1.1.1'></div>
    </div>
    <div class='g2'>
      <div class='ff'><label>Default VLAN</label><input id='org-vlan' autocomplete='off' value='${d.vlan||""}' placeholder='10'></div>
      <div class='ff'><label>Network Bridge</label><input id='org-bridge' autocomplete='off' value='${d.bridge||""}' placeholder='vmbr0'></div>
    </div>
    <div class='g2'>
      <div class='ff'><label>Storage Pool</label><input id='org-storage' autocomplete='off' value='${d.storage||""}' placeholder='local-lvm'></div>
      <div class='ff'><label>Template VM Name</label><input id='org-tmpl' autocomplete='off' value='${d.templateName||""}' placeholder='win2025-template'></div>
    </div>
    <div class='ff'><label>Windows Admin Password</label><input id='org-pass' autocomplete='off' data-1p-ignore data-lpignore='true' value='${d.pass||""}' placeholder='Asdf1234!' style='font-family:var(--mono)'></div>
    <div class='ff'><label>AD Domain (auto-join all VMs in this org)</label><input id='org-domain' autocomplete='off' value='${d.domain||""}' placeholder='contoso.local'></div>
    </div>`;
}

function closeModal() { $('modal-bg').classList.remove('open'); }

function renderAll() {
  renderTree(''); renderOverview(); // Always show full tree on data changes
  if (S.view==='deploy') { populateDepOrgSel(); renderDeploy(); }
  if (S.view==='templates') loadTemplates();
  if (S.view==='admin') loadUsers();
  if (S.selVm && $('view-vm-detail').style.display !== 'none') {
    const _rv = vb(S.selVm); if (_rv) { _vdRenderHeader(_rv); _vdRenderTabs(_rv); }
  } else if (S.selHost) showHostDetail(S.selHost);
  else if (S.selOrg) showOrgDetail(S.selOrg);
}

// ── App Init ───────────────────────────────────────────────────────────────────
async function initApp() {
  applyRoleUI();
  await loadState();
  syncSettingsForm();
  renderAll();
  startVmPolling();

  // Save current config as template button in deploy view
  const deployPh = document.querySelector('#view-deploy .ph-r');
  if (deployPh && !$('btn-save-tmpl')) {
    const btn = document.createElement('button');
    btn.id='btn-save-tmpl'; btn.className='btn btn-g btn-sm';
    btn.innerHTML='<span style="display:inline-flex;align-items:center;gap:5px"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Save as Template</span>'; btn.onclick=()=>openModal('new-template');
    deployPh.insertBefore(btn, deployPh.firstChild);
  }

  populateDepOrgSel();
  // Restore running deploy if any
  const status = await api('GET','/api/deploy/status').catch(()=>({}));
  if (status.running) {
    S.deploying=true; $('dep-btn').disabled=true; $('abort-btn').style.display='';
    $('live-b').innerHTML='<span style="font-size:10px;color:var(--green);font-family:var(--mono);animation:blink .8s infinite">● LIVE</span>';
    $('deploy-status-bar').classList.add('visible');
    $('dsb-text').textContent='Deploy running...';
    _pollInterval = setInterval(pollDeployStatus, 1500);
  } else if (status.log) {
    $('log').textContent = status.log;
    if (status.exitCode!==0&&status.exitCode!==undefined) {
      $('log').style.color='var(--red)'; $('log').style.borderColor='var(--red)';
      setTimeout(()=>{ $('log').style.color=''; $('log').style.borderColor=''; }, 5000);
    }
  }
}

// Check existing session on load
(async () => {
  const token = getToken();
  if (token) {
    try {
      const me = await fetch('/api/auth/me', { headers:{'x-session':token} });
      if (me.ok) {
        const d = await me.json();
        S.session = { username:d.username, role:d.role };
        hideLogin(); await initApp(); return;
      }
    } catch(_) {}
  }
  showLogin();
})();
</script>
</body>
</html>
HTML_EOF

  # ---------------------------------------------------------------------------
  # backend/server.js
  # ---------------------------------------------------------------------------
  cat > "${DIR}/backend/server.js" << 'JS_EOF'
const express     = require('express');
const cors        = require('cors');
const fs          = require('fs');
const path        = require('path');
const https       = require('https');
const { exec, execSync } = require('child_process');
const crypto      = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

// ── Paths ────────────────────────────────────────────────────────────────────
const DATA         = path.join(__dirname, 'data', 'config.json');
const USERS_FILE   = path.join(__dirname, 'data', 'users.json');
const TEMPLATES_FILE = path.join(__dirname, 'data', 'templates.json');
const SESSIONS_FILE  = path.join(__dirname, 'data', 'sessions.json');
const ORGS_FILE         = path.join(__dirname, 'data', 'organisations.json');
const INV  = path.join(__dirname, '../ansible/inventory/hosts.ini');
const ADIR = path.join(__dirname, '../ansible');

fs.mkdirSync(path.dirname(DATA), { recursive: true });
fs.mkdirSync(path.dirname(INV),  { recursive: true });

// ── Generic loaders ──────────────────────────────────────────────────────────
const loadJson = (file, def) => { try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return def; } };
const saveJson = (file, data) => fs.writeFileSync(file, JSON.stringify(data, null, 2));

const load  = ()  => loadJson(DATA, { hosts:[], vms:[], settings:{} });
const save  = (c) => saveJson(DATA, c);

// ── Session store ────────────────────────────────────────────────────────────
let sessions = loadJson(SESSIONS_FILE, {});
const SESSION_TTL = 24 * 60 * 60 * 1000; // 24 hours

function createSession(username, role) {
  const token = crypto.randomBytes(32).toString('hex');
  sessions[token] = { username, role, created: Date.now() };
  saveJson(SESSIONS_FILE, sessions);
  return token;
}
function getSession(token) {
  const s = sessions[token];
  if (!s) return null;
  if (Date.now() - s.created > SESSION_TTL) { delete sessions[token]; saveJson(SESSIONS_FILE, sessions); return null; }
  return s;
}
function destroySession(token) { delete sessions[token]; saveJson(SESSIONS_FILE, sessions); }

// ── Auth middleware ──────────────────────────────────────────────────────────
function auth(minRole) {
  const ORDER = { readonly: 0, deploy: 1, admin: 2 };
  return (req, res, next) => {
    const token = req.headers['x-session'] || req.query?.token || req.cookies?.session;
    if (!token) return res.status(401).json({ error: 'Not authenticated' });
    const s = getSession(token);
    if (!s) return res.status(401).json({ error: 'Session expired' });
    if (minRole && ORDER[s.role] < ORDER[minRole]) return res.status(403).json({ error: 'Insufficient permissions' });
    req.session = s;
    next();
  };
}

// ── Internal auth (bcrypt, no PAM/system users needed) ───────────────────────
const bcrypt = require('bcryptjs');
const BCRYPT_ROUNDS = 10;

function hashPassword(pw) { return bcrypt.hashSync(pw, BCRYPT_ROUNDS); }
function verifyPassword(pw, hash) {
  if (!hash) return false;  // no hash set — deny
  if (!hash.startsWith('$2')) return pw === hash;  // legacy plain-text
  return bcrypt.compareSync(pw, hash);
}

// Bootstrap: create default admin if no users exist
function ensureUsers() {
  const users = loadJson(USERS_FILE, {});
  let changed = false;
  if (Object.keys(users).length === 0) {
    // No users at all — create default admin
    users['admin'] = {
      role: 'admin',
      passwordHash: hashPassword('admin'),
      added: new Date().toISOString(),
      mustChangePassword: true,
    };
    changed = true;
    console.log('[windows-deployment] Created default admin user (password: admin) — change immediately!');
  } else {
    // Migrate any existing users that have no passwordHash (old PAM-based records)
    for (const [uname, u] of Object.entries(users)) {
      if (!u.passwordHash) {
        // Assign a random initial password — admin must reset
        const tempPw = require('crypto').randomBytes(8).toString('hex');
        u.passwordHash = hashPassword(tempPw);
        u.mustChangePassword = true;
        u.migrated = true;
        changed = true;
        console.log(`[windows-deployment] Migrated user '${uname}' — temp password: ${tempPw} (please reset via UI)`);
      }
    }
    // Also ensure there is at least one admin
    const hasAdmin = Object.values(users).some(u => u.role === 'admin');
    if (!hasAdmin) {
      users['admin'] = {
        role: 'admin',
        passwordHash: hashPassword('admin'),
        added: new Date().toISOString(),
        mustChangePassword: true,
      };
      changed = true;
      console.log('[windows-deployment] No admin found — created default admin (password: admin)');
    }
  }
  if (changed) saveJson(USERS_FILE, users);
}
ensureUsers();

// ── Auth endpoints ────────────────────────────────────────────────────────────
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) return res.status(400).json({ error: 'Username and password required' });
  const users = loadJson(USERS_FILE, {});
  const user = users[username];
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  if (!verifyPassword(password, user.passwordHash)) return res.status(401).json({ error: 'Invalid credentials' });
  const token = createSession(username, user.role);
  res.json({ token, username, role: user.role, mustChangePassword: !!user.mustChangePassword });
});

app.post('/api/auth/logout', auth('readonly'), (req, res) => {
  const token = req.headers['x-session'];
  destroySession(token);
  res.json({ success: true });
});

app.get('/api/auth/me', auth('readonly'), (req, res) => {
  res.json({ username: req.session.username, role: req.session.role });
});

// ── User management (admin only) ──────────────────────────────────────────────
app.get('/api/users', auth('admin'), (req, res) => {
  const users = loadJson(USERS_FILE, {});
  res.json(Object.entries(users).map(([username, u]) => ({ username, ...u })));
});

app.post('/api/users', auth('admin'), (req, res) => {
  const { username, role, password } = req.body;
  if (!username || !['admin','deploy','readonly'].includes(role) || !password)
    return res.status(400).json({ error: 'username, role and password required' });
  if (password.length < 8) return res.status(400).json({ error: 'Password must be at least 8 characters' });
  const users = loadJson(USERS_FILE, {});
  if (users[username]) return res.status(409).json({ error: 'Username already exists' });
  users[username] = {
    role,
    passwordHash: hashPassword(password),
    added: new Date().toISOString(),
    addedBy: req.session.username,
  };
  saveJson(USERS_FILE, users);
  res.json({ success: true });
});

app.put('/api/users/:username', auth('admin'), (req, res) => {
  const { role, password } = req.body;
  if (role && !['admin','deploy','readonly'].includes(role)) return res.status(400).json({ error: 'Invalid role' });
  const users = loadJson(USERS_FILE, {});
  if (!users[req.params.username]) return res.status(404).json({ error: 'User not found' });
  if (role) users[req.params.username].role = role;
  if (password) {
    if (password.length < 8) return res.status(400).json({ error: 'Password must be at least 8 characters' });
    users[req.params.username].passwordHash = hashPassword(password);
    users[req.params.username].mustChangePassword = false;
  }
  saveJson(USERS_FILE, users);
  res.json({ success: true });
});

// Change own password (any authenticated user)
app.post('/api/auth/change-password', auth('readonly'), (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) return res.status(400).json({ error: 'currentPassword and newPassword required' });
  if (newPassword.length < 8) return res.status(400).json({ error: 'Password must be at least 8 characters' });
  const users = loadJson(USERS_FILE, {});
  const user = users[req.session.username];
  if (!user) return res.status(404).json({ error: 'User not found' });
  if (!verifyPassword(currentPassword, user.passwordHash)) return res.status(401).json({ error: 'Current password incorrect' });
  user.passwordHash = hashPassword(newPassword);
  user.mustChangePassword = false;
  saveJson(USERS_FILE, users);
  res.json({ success: true });
});

app.delete('/api/users/:username', auth('admin'), (req, res) => {
  if (req.params.username === req.session.username) return res.status(400).json({ error: 'Cannot remove yourself' });
  const users = loadJson(USERS_FILE, {});
  delete users[req.params.username];
  saveJson(USERS_FILE, users);
  res.json({ success: true });
});

// ── Deployment Templates ───────────────────────────────────────────────────────
app.get('/api/templates', auth('readonly'), (req, res) => {
  const templates = loadJson(TEMPLATES_FILE, []);
  res.json(templates);
});

app.post('/api/templates', auth('deploy'), (req, res) => {
  const { name, description, vms, settings } = req.body;
  if (!name) return res.status(400).json({ error: 'name required' });
  const templates = loadJson(TEMPLATES_FILE, []);
  // deploy role can only create, admin can create global
  const isGlobal = req.session.role === 'admin' ? (req.body.global ?? true) : false;
  templates.push({
    id: Date.now().toString(),
    name, description: description || '',
    vms: vms || [],
    settings: settings || {},
    global: isGlobal,
    owner: req.session.username,
    created: new Date().toISOString(),
    updated: new Date().toISOString(),
  });
  saveJson(TEMPLATES_FILE, templates);
  res.json({ success: true });
});

app.put('/api/templates/:id', auth('deploy'), (req, res) => {
  const templates = loadJson(TEMPLATES_FILE, []);
  const idx = templates.findIndex(t => t.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: 'Not found' });
  const t = templates[idx];
  // deploy role can only edit own templates
  if (req.session.role === 'deploy' && t.owner !== req.session.username)
    return res.status(403).json({ error: 'Cannot edit templates you do not own' });
  templates[idx] = { ...t, ...req.body, id: t.id, owner: t.owner, created: t.created, updated: new Date().toISOString() };
  saveJson(TEMPLATES_FILE, templates);
  res.json({ success: true });
});

app.delete('/api/templates/:id', auth('deploy'), (req, res) => {
  const templates = loadJson(TEMPLATES_FILE, []);
  const t = templates.find(t => t.id === req.params.id);
  if (!t) return res.status(404).json({ error: 'Not found' });
  if (req.session.role === 'deploy' && t.owner !== req.session.username)
    return res.status(403).json({ error: 'Cannot delete templates you do not own' });
  saveJson(TEMPLATES_FILE, templates.filter(x => x.id !== req.params.id));
  res.json({ success: true });
});

// Export template as JSON download
app.get('/api/templates/:id/export', auth('readonly'), (req, res) => {
  const templates = loadJson(TEMPLATES_FILE, []);
  const t = templates.find(t => t.id === req.params.id);
  if (!t) return res.status(404).json({ error: 'Not found' });
  res.setHeader('Content-Disposition', `attachment; filename="${t.name.replace(/[^a-z0-9]/gi,'_')}.json"`);
  res.setHeader('Content-Type', 'application/json');
  res.send(JSON.stringify({ ...t, _export_version: 1 }, null, 2));
});

// Import template from uploaded JSON
app.post('/api/templates/import', auth('deploy'), express.json({ limit: '1mb' }), (req, res) => {
  const t = req.body;
  if (!t?.name || !Array.isArray(t?.vms)) return res.status(400).json({ error: 'Invalid template JSON' });
  const templates = loadJson(TEMPLATES_FILE, []);
  templates.push({
    id: Date.now().toString(),
    name: t.name + ' (imported)',
    description: t.description || '',
    vms: t.vms || [],
    settings: t.settings || {},
    global: req.session.role === 'admin',
    owner: req.session.username,
    created: new Date().toISOString(),
    updated: new Date().toISOString(),
  });
  saveJson(TEMPLATES_FILE, templates);
  res.json({ success: true });
});

// ── Hosts ─────────────────────────────────────────────────────────────────────
// ── Organisations ────────────────────────────────────────────────────────────
app.get('/api/organisations', auth('readonly'), (req, res) => {
  res.json(loadJson(ORGS_FILE, []));
});

app.post('/api/organisations', auth('admin'), (req, res) => {
  const { name, description, defaults } = req.body;
  if (!name) return res.status(400).json({ error: 'name required' });
  const orgs = loadJson(ORGS_FILE, []);
  const org = { id: Date.now().toString(), name, description: description||'',
    defaults: defaults || {}, created: new Date().toISOString(), _open: true };
  orgs.push(org);
  saveJson(ORGS_FILE, orgs);
  res.json({ success: true, org });
});

app.put('/api/organisations/:id', auth('admin'), (req, res) => {
  const orgs = loadJson(ORGS_FILE, []);
  const idx = orgs.findIndex(o => o.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: 'Not found' });
  orgs[idx] = { ...orgs[idx], ...req.body, id: req.params.id };
  saveJson(ORGS_FILE, orgs);
  res.json({ success: true });
});

app.delete('/api/organisations/:id', auth('admin'), (req, res) => {
  const orgs = loadJson(ORGS_FILE, []);
  const c = load();
  // Unassign hosts from this org
  c.hosts.forEach(h => { if (h.orgId === req.params.id) h.orgId = ''; });
  save(c);
  saveJson(ORGS_FILE, orgs.filter(o => o.id !== req.params.id));
  res.json({ success: true });
});

app.get('/api/hosts', auth('readonly'), (req, res) =>
  res.json(load().hosts.map(h => ({ ...h, tokenSecret: '***' })))
);

app.post('/api/hosts', auth('admin'), async (req, res) => {
  const { name, host, node, tokenId, tokenSecret, templateName, storage, bridge, defaultVlan, orgId } = req.body;
  if (!name || !host || !tokenId || !tokenSecret) return res.status(400).json({ error: 'name, host, tokenId, tokenSecret required' });
  const c = load();
  c.hosts.push({
    id: Date.now().toString(), name, host, node: node||'pve', tokenId, tokenSecret,
    templateName: templateName||'win2025-template', storage: storage||'local-lvm',
    bridge: bridge||'vmbr0', defaultVlan: defaultVlan||'', orgId: orgId||''
  });
  save(c); res.json({ success: true });
});

app.put('/api/hosts/:id', auth('admin'), (req, res) => {
  const c = load(); const i = c.hosts.findIndex(h => h.id === req.params.id);
  if (i === -1) return res.status(404).json({ error: 'Host not found' });
  const update = { ...req.body }; if (!update.tokenSecret) delete update.tokenSecret;
  c.hosts[i] = { ...c.hosts[i], ...update, id: req.params.id };
  save(c); res.json({ success: true });
});

app.delete('/api/hosts/:id', auth('admin'), (req, res) => {
  const c = load(); c.hosts = c.hosts.filter(h => h.id !== req.params.id); save(c); res.json({ success: true });
});

// ── VMs ───────────────────────────────────────────────────────────────────────
app.get('/api/vms', auth('readonly'), (req, res) => res.json(load().vms || []));

app.post('/api/vms', auth('deploy'), (req, res) => {
  const c = load();
  const vm = { id: Date.now().toString(), ...req.body, name: req.body.hostname, status: 'pending', prog: 0 };
  c.vms = [...(c.vms||[]), vm]; save(c); res.json({ success: true, vm });
});

app.put('/api/vms/:id', auth('deploy'), (req, res) => {
  const c = load(); const i = c.vms.findIndex(v => v.id === req.params.id);
  if (i === -1) return res.status(404).json({ error: 'Not found' });
  c.vms[i] = { ...c.vms[i], ...req.body, id: req.params.id, name: req.body.hostname || c.vms[i].hostname };
  save(c); res.json({ success: true });
});

app.delete('/api/vms/:id', auth('deploy'), (req, res) => {
  const c = load(); c.vms = c.vms.filter(v => v.id !== req.params.id); save(c); res.json({ success: true });
});

// ── Settings ───────────────────────────────────────────────────────────────────
app.get('/api/settings', auth('readonly'), (req, res) => res.json(load().settings || {}));
app.put('/api/settings', auth('admin'), (req, res) => { const c = load(); c.settings = req.body; save(c); res.json({ success: true }); });

// ── VM Power-Actions ───────────────────────────────────────────────────────────
app.post('/api/vms/:id/power', auth('deploy'), async (req, res) => {
  const { action } = req.body; // start | stop | reboot | shutdown
  if (!['start','stop','reboot','shutdown'].includes(action))
    return res.status(400).json({ error: 'action must be start|stop|reboot|shutdown' });
  const c = load();
  const vm = c.vms.find(v => v.id === req.params.id);
  if (!vm) return res.status(404).json({ error: 'VM not found' });
  const h = c.hosts.find(h => h.id === vm.hostId);
  if (!h) return res.status(400).json({ error: 'Host not found' });
  const script = `
import sys, json
from proxmoxer import ProxmoxAPI
host, token_id, token_secret, node, vmid, action = sys.argv[1:7]
if '!' in token_id:
    api_user, token_name = token_id.split('!', 1)
else:
    api_user, token_name = 'root@pam', token_id
px = ProxmoxAPI(host, user=api_user, token_name=token_name, token_value=token_secret, verify_ssl=False)
vm = px.nodes(node).qemu(int(vmid))
if action == 'start':    vm.status.start.post()
elif action == 'stop':   vm.status.stop.post()
elif action == 'reboot': vm.status.reboot.post()
elif action == 'shutdown': vm.status.shutdown.post()
print('OK')
`;
  if (!vm.vmid) return res.status(400).json({ error: 'VMID not known yet — VM may not exist in Proxmox' });
  try {
    execSync(`python3 -c ${JSON.stringify(script)} ${h.host} ${h.tokenId} ${h.tokenSecret} ${h.node} ${vm.vmid} ${action}`, { timeout: 15000 });
    res.json({ success: true });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── VM Proxmox live status ─────────────────────────────────────────────────────
app.get('/api/vms/proxmox-status', auth('readonly'), async (req, res) => {
  const c = load(); const h = c.hosts?.[0];
  if (!h || !c.vms?.length) return res.json({});
  const script = `
import json, sys
from proxmoxer import ProxmoxAPI
host, token_id, token_secret, node = sys.argv[1:5]
if '!' in token_id:
    api_user, token_name = token_id.split('!', 1)
else:
    api_user, token_name = 'root@pam', token_id
try:
    px = ProxmoxAPI(host, user=api_user, token_name=token_name, token_value=token_secret, verify_ssl=False)
    vms = px.nodes(node).qemu.get()
    print(json.dumps(vms))
except Exception as e:
    print(json.dumps([]))
`;
  try {
    const out = execSync(`python3 -c ${JSON.stringify(script)} ${JSON.stringify(h.host)} ${JSON.stringify(h.tokenId)} ${JSON.stringify(h.tokenSecret)} ${JSON.stringify(h.node)}`, { timeout: 10000 }).toString();
    const pveVms = JSON.parse(out);
    const statusMap = {}; S._pveStatus = statusMap;
    for (const vm of pveVms) {
      statusMap[vm.name] = { vmid: vm.vmid, status: vm.status, uptime: vm.uptime||0, cpu: vm.cpu||0, mem: vm.mem||0, maxmem: vm.maxmem||0 };
    }
    res.json(statusMap);
  } catch(e) { res.json({}); }
});

// ── RDP file download ──────────────────────────────────────────────────────────
app.get('/api/vms/:id/rdp', auth('readonly'), (req, res) => {
  const c = load();
  const vm = c.vms.find(v => v.id === req.params.id);
  if (!vm) return res.status(404).json({ error: 'VM not found' });
  const rdp = [
    'auto connect:i:1',
    `full address:s:${vm.ip}`,
    'username:s:Administrator',
    'authentication level:i:2',
    'prompt for credentials:i:0',
    'use multimon:i:0',
    'session bpp:i:32',
    `desktopwidth:i:1920`,
    `desktopheight:i:1080`,
    'connection type:i:7',
    'networkautodetect:i:1',
    'bandwidthautodetect:i:1',
    'disable wallpaper:i:0',
    'allow font smoothing:i:1',
  ].join('\r\n');
  res.setHeader('Content-Disposition', `attachment; filename="${vm.hostname}.rdp"`);
  res.setHeader('Content-Type', 'application/x-rdp');
  res.send(rdp);
});

// ── Deploy history ─────────────────────────────────────────────────────────────
// ── Per-user deploy sessions ─────────────────────────────────────────────────
// Map: username -> { running, log, exitCode, proc, vmids, startedAt, orgId, orgName, vms }
const deploys = new Map();
const DEPLOY_HIST_FILE = path.join(__dirname, 'data', 'deploy_history.json');

// Restore persisted sessions on startup
(function restoreDeploys() {
  const f = path.join(__dirname, 'data', 'deploys.json');
  try {
    const saved = JSON.parse(fs.readFileSync(f, 'utf8'));
    for (const [user, s] of Object.entries(saved)) {
      if (s.running) s.log += '\n[restarted -- deploy reset]\n';
      s.running = false; s.proc = null;
      deploys.set(user, s);
    }
  } catch(_) {}
})();

function persistDeploys() {
  const f = path.join(__dirname, 'data', 'deploys.json');
  const out = {};
  for (const [user, s] of deploys) {
    out[user] = { running: s.running, log: s.log, exitCode: s.exitCode,
                  vmids: s.vmids, startedAt: s.startedAt,
                  orgId: s.orgId, orgName: s.orgName, vms: s.vms };
  }
  try { fs.writeFileSync(f, JSON.stringify(out)); } catch(_) {}
}

function getOrInitDeploy(username) {
  if (!deploys.has(username)) {
    deploys.set(username, { running:false, log:'', exitCode:0, proc:null,
                             vmids:[], startedAt:null, orgId:'', orgName:'', vms:[] });
  }
  return deploys.get(username);
}

function appendHistory(entry) {
  const hist = loadJson(DEPLOY_HIST_FILE, []);
  hist.unshift({ ...entry, id: Date.now().toString() });
  saveJson(DEPLOY_HIST_FILE, hist.slice(0, 100));
}

// ── History ───────────────────────────────────────────────────────────────────
app.get('/api/deploy/history', auth('readonly'), (req, res) => {
  const hist = loadJson(DEPLOY_HIST_FILE, []);
  res.json(req.session.role === 'admin' ? hist : hist.filter(h => h.startedBy === req.session.username));
});

// ── Admin: all sessions ───────────────────────────────────────────────────────
app.get('/api/deploy/all', auth('admin'), (req, res) => {
  const result = [];
  for (const [username, s] of deploys) {
    result.push({
      username, running: s.running, exitCode: s.exitCode,
      startedAt: s.startedAt, orgId: s.orgId, orgName: s.orgName,
      vmCount: s.vms?.length || 0, vms: s.vms || [],
      logTail: (s.log || '').slice(-800),
    });
  }
  res.json(result);
});

// ── Admin: abort any user ─────────────────────────────────────────────────────
app.post('/api/deploy/abort-user', auth('admin'), (req, res) => {
  const { username } = req.body;
  const s = deploys.get(username);
  if (!s?.running) return res.status(400).json({ error: 'No active deploy for that user' });
  s.log += '\n[windows-deployment] ABORT by admin...\n';
  if (s.proc) {
    try { process.kill(-s.proc.pid, 'SIGTERM'); } catch(_) {}
    try { s.proc.kill('SIGKILL'); } catch(_) {}
    s.proc = null;
  }
  s.running = false; s.exitCode = 130;
  persistDeploys();
  res.json({ success: true });
});

// ── Deploy (scoped per user + org) ────────────────────────────────────────────
app.post('/api/deploy', auth('deploy'), (req, res) => {
  const username = req.session.username;
  const session  = getOrInitDeploy(username);
  if (session.running) return res.status(409).json({ error: 'You already have a deploy running' });

  const { orgId } = req.body;
  if (!orgId) return res.status(400).json({ error: 'orgId required' });

  const c    = load();
  const orgs = loadJson(ORGS_FILE, []);
  const org  = orgs.find(o => o.id === orgId);
  if (!org) return res.status(400).json({ error: 'Organisation not found' });

  const orgHosts = (c.hosts || []).filter(h => h.orgId === orgId);
  if (!orgHosts.length) return res.status(400).json({ error: 'No hosts in this organisation' });

  const orgVms = (c.vms || []).filter(v => orgHosts.some(h => h.id === v.hostId));
  if (!orgVms.length) return res.status(400).json({ error: 'No VMs in this organisation' });

  const s   = c.settings || {};
  const od  = org.defaults || {};
  const h   = orgHosts[0];
  const pick = (...vals) => vals.find(v => v !== undefined && v !== null && v !== '') || '';

  const ROLE_ORDER = ['dc','fileserver','backupserver','rds_broker','rds_sessionhost','printserver','mgmt'];
  const activeRoles = ROLE_ORDER.filter(role => orgVms.some(v => v.role === role));

  const safeUser = username.replace(/[^a-z0-9_]/gi, '_');
  const invFile  = path.join(ADIR, 'inventory', `hosts_${safeUser}.ini`);
  const vmidFile = path.join(ADIR, 'inventory', `_vmids_${safeUser}.json`);
  const evFile   = path.join(ADIR, 'inventory', `_extra_${safeUser}.json`);

  let ini = `# Deploy by ${username} -- org: ${org.name}\n`;
  ini += `[windows:children]\n${activeRoles.join('\n')}\n\n`;
  activeRoles.forEach(role => {
    ini += `[${role}]\n`;
    orgVms.filter(v => v.role === role).forEach(v => {
      let hostLine = `${v.hostname} ansible_host=${v.ip}`;
      // For DC role: embed per-host AD vars directly in inventory
      // Non-DC VMs get DC IPs as DNS (if DCs exist)
      if (v.role !== 'dc' && dcVms.length > 0) {
        hostLine += ` dns_primary=${dcDns1} dns_secondary=${dcDns2}`;
      }
      if (v.role === 'dc') {
        const ac = v.adConfig || {};
        const repl  = ac.replPartner  ? (orgVms.find(vv=>vv.id===ac.replPartner)?.ip||'')  : '';
        const foip  = ac.failPartner  ? (orgVms.find(vv=>vv.id===ac.failPartner)?.ip||'')  : '';
        const dcDomain  = pick(ac.domain, od.domain, '');
        const dcNetbios = pick(ac.netbios, dcDomain.split('.')[0]?.toUpperCase()||'');
        const dcPw      = pick(ac.safeModePw, '');
        if (dcDomain) {
          hostLine += ` dc_domain=${dcDomain} dc_netbios=${dcNetbios} dc_forest_mode=${ac.forestMode||'WinThreshold'}`;
          hostLine += ` dc_safe_mode_pw=${JSON.stringify(dcPw)} dc_is_primary=${ac.isPrimary!==false}`;
          hostLine += ` dc_is_rodc=${!!ac.isRODC} dc_enable_repl=${!!ac.enableRepl}`;
          hostLine += ` dc_repl_partner_ip=${repl} dc_dhcp_failover=${!!ac.dhcpFailover} dc_failover_ip=${foip}`;
          hostLine += ` dc_dns_zones=${JSON.stringify(JSON.stringify(ac.dnsZones||[]))}`;
          hostLine += ` dc_dhcp_scopes=${JSON.stringify(JSON.stringify(ac.dhcpScopes||[]))}`;
          hostLine += ` dc_ip=${v.ip}`;
        }
      }
      ini += hostLine + '\n';
    });
    ini += '\n';
  });

  const resolvedPass = pick(od.pass, s.pass, 'Asdf1234!');
  const resolvedGw   = pick(od.gateway, '172.16.10.1');
  const resolvedPfx  = pick(od.pfx, 24);
  // DC IPs for non-DC VMs — if DCs exist, use them as DNS
  const dcVms = orgVms.filter(v => v.role === 'dc').sort((a,b) => a.ip.localeCompare(b.ip));
  const orgDns1 = pick(od.dns1, '8.8.8.8');
  const orgDns2 = pick(od.dns2, '1.1.1.1');
  // DCs use org DNS; all other servers use DC IPs as DNS
  const dcDns1  = dcVms[0]?.ip || orgDns1;
  const dcDns2  = dcVms[1]?.ip || orgDns2;

  ini += `[windows:vars]
ansible_user=Administrator
ansible_password=${resolvedPass}
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_port=5985
ansible_winrm_server_cert_validation=ignore
ansible_winrm_scheme=http
network_gateway=${resolvedGw}
network_prefix_length=${resolvedPfx}
dns_primary=${orgDns1}
dns_secondary=${orgDns2}
win_timezone=${s.tz||'W. Europe Standard Time'}
win_locale=${s.locale||'de-CH'}
`;
  fs.writeFileSync(invFile, ini);
  try { fs.writeFileSync(vmidFile, '[]'); } catch(_) {}

  const serversJson = orgVms.map(v => {
    const ac = v.adConfig || {};
    return {
      hostname: v.hostname, ip: v.ip, cpus: v.cpus||2, ram: v.ram||4096, disk: v.disk||75, role: v.role,
      vlan: pick(v.vlan, h.defaultVlan, od.vlan, ''),
      bridge: pick(v.bridge, h.bridge, od.bridge, 'vmbr0'),
      // AD config (only used for dc role)
      dc_domain:        pick(ac.domain, od.domain, ''),
      dc_netbios:       pick(ac.netbios, pick(ac.domain, od.domain, '').split('.')[0]?.toUpperCase()||''),
      dc_forest_mode:   ac.forestMode || 'WinThreshold',
      dc_safe_mode_pw:  pick(ac.safeModePw, ''),
      dc_is_primary:    ac.isPrimary !== false,
      dc_is_rodc:       !!ac.isRODC,
      dc_enable_repl:   !!ac.enableRepl,
      dc_repl_partner:  ac.replPartner  ? (orgVms.find(vv=>vv.id===ac.replPartner)?.ip||'') : '',
      dc_dhcp_failover: !!ac.dhcpFailover,
      dc_failover_ip:   ac.failPartner  ? (orgVms.find(vv=>vv.id===ac.failPartner)?.ip||'')  : '',
      dc_dns_zones:     JSON.stringify(ac.dnsZones  || []),
      dc_dhcp_scopes:   JSON.stringify(ac.dhcpScopes || []),
    };
  });

  const extraVars = {
    proxmox_host: h.host, proxmox_node: h.node,
    proxmox_template_name: pick(h.templateName, od.templateName, 'win2025-template'),
    proxmox_storage: pick(h.storage, od.storage, 'local-lvm'),
    proxmox_bridge: pick(h.bridge, od.bridge, 'vmbr0'),
    proxmox_token_id: h.tokenId, proxmox_token_secret: h.tokenSecret,
    win_admin_pass: resolvedPass,
    network_gateway: resolvedGw, network_prefix_length: resolvedPfx,
    dns_primary: orgDns1, dns_secondary: orgDns2,
    win_timezone: s.tz||'W. Europe Standard Time', win_locale: s.locale||'de-CH',
  };
  fs.writeFileSync(evFile, JSON.stringify({ ...extraVars, servers: serversJson, vmid_file: vmidFile }));

  const deployStart = new Date().toISOString();
  session.running   = true;
  session.exitCode  = 0;
  session.startedAt = deployStart;
  session.orgId     = orgId;
  session.orgName   = org.name;
  session.vmids     = [];
  session.vms       = orgVms.map(v => ({ hostname:v.hostname, ip:v.ip, role:v.role, orgName:org.name }));
  session.log       = `[windows-deployment] Deploy started by ${username} -- org: ${org.name}\n`;
  persistDeploys();
  res.json({ success: true });

  const cmd = `cd "${ADIR}" && $(python3 -c "import shutil; print(shutil.which('ansible-playbook') or '/usr/local/bin/ansible-playbook')") site.yml -i inventory/hosts_${safeUser}.ini -e "@inventory/_extra_${safeUser}.json" 2>&1`;
  const proc = exec(cmd);
  session.proc = proc;

  let flushTimer = null;
  const flush = () => persistDeploys();
  proc.stdout?.on('data', d => { session.log += d; clearTimeout(flushTimer); flushTimer = setTimeout(flush, 500); });
  proc.stderr?.on('data', d => { session.log += d; clearTimeout(flushTimer); flushTimer = setTimeout(flush, 500); });
  proc.on('close', code => {
    session.running = false; session.proc = null; session.exitCode = code;
    try { session.vmids = JSON.parse(fs.readFileSync(vmidFile, 'utf8')); } catch(_) {}
    session.log += `\n[windows-deployment] Finished with exit code ${code}\n`;
    persistDeploys();
    appendHistory({
      startedAt: deployStart, finishedAt: new Date().toISOString(),
      startedBy: username, orgId, orgName: org.name,
      exitCode: code, vmCount: orgVms.length,
      vms: orgVms.map(v => ({ hostname:v.hostname, ip:v.ip, role:v.role })),
    });
    try { fs.unlinkSync(evFile); } catch(_) {}
    try { fs.unlinkSync(invFile); } catch(_) {}
  });
});

app.get('/api/deploy/status', auth('readonly'), (req, res) => {
  const s = getOrInitDeploy(req.session.username);
  res.json({ running: s.running, log: s.log, exitCode: s.exitCode, vmids: s.vmids });
});

app.post('/api/deploy/abort', auth('deploy'), (req, res) => {
  const username = req.session.username;
  const s = deploys.get(username);
  if (!s?.running) return res.status(400).json({ error: 'No deploy running' });
  s.log += '\n[windows-deployment] ABORT requested...\n';
  if (s.proc) {
    try { process.kill(-s.proc.pid, 'SIGTERM'); } catch(_) {}
    try { s.proc.kill('SIGKILL'); } catch(_) {}
    s.proc = null;
  }
  s.running = false; s.exitCode = 130;
  persistDeploys();

  const vmids = s.vmids?.length ? s.vmids : [];
  if (!vmids.length) {
    s.log += '[windows-deployment] No VMs to clean up.\n';
    persistDeploys();
    return res.json({ success: true, cleaned: [] });
  }
  s.log += `[windows-deployment] Cleaning up ${vmids.length} VM(s)...\n`;
  persistDeploys();
  const c = load();
  const h = c.hosts?.find(h => h.orgId === s.orgId) || c.hosts?.[0];
  if (!h) return res.json({ success: true, cleaned: [], note: 'No host found' });
  const cleanCmd = `python3 ${path.join(ADIR,'pve_cleanup.py')} '${h.host}' '${h.tokenId}' '${h.tokenSecret}' '${h.node}' '${vmids.join(',')}'`;
  exec(cleanCmd, (err, stdout) => {
    s.log += stdout || '';
    s.log += err ? `[cleanup error] ${err.message}\n` : '[windows-deployment] Cleanup done.\n';
    persistDeploys();
  });
  res.json({ success: true, cleaning: vmids });
});

// ── AD Setup endpoint ────────────────────────────────────────────────────────
app.post('/api/vms/:id/ad-setup', auth('deploy'), (req, res) => {
  const c  = load();
  const vm = (c.vms||[]).find(v => v.id === req.params.id);
  if (!vm)          return res.status(404).json({ error: 'VM not found' });
  if (!vm.vmid)     return res.status(400).json({ error: 'VM not deployed yet (no VMID)' });
  if (vm.role !== 'dc') return res.status(400).json({ error: 'AD setup only for Domain Controller role' });
  const h   = (c.hosts||[]).find(h => h.id === vm.hostId);
  if (!h)   return res.status(400).json({ error: 'Host not found' });
  const orgs = loadJson(ORGS_FILE, []);
  const org  = orgs.find(o => o.id === h.orgId);
  const od   = org?.defaults || {};
  const s    = c.settings || {};
  const ac   = vm.adConfig || {};
  const pick = (...vals) => vals.find(v => v !== undefined && v !== null && v !== '') || '';
  const partnerVm = ac.replPartner ? (c.vms||[]).find(v => v.id === ac.replPartner) : null;
  const failVm    = ac.failPartner  ? (c.vms||[]).find(v => v.id === ac.failPartner)  : null;
  const adVars = {
    dc_hostname:          vm.hostname,
    dc_ip:                vm.ip,
    dc_domain:            pick(ac.domain, od.domain, 'contoso.local'),
    dc_netbios:           pick(ac.netbios, pick(ac.domain, od.domain, '').split('.')[0]?.toUpperCase()),
    dc_forest_mode:       ac.forestMode || 'WinThreshold',
    dc_safe_mode_pw:      pick(ac.safeModePw, od.pass, s.pass, 'Asdf1234!'),
    dc_is_primary:        ac.isPrimary !== false,
    dc_is_rodc:           !!ac.isRODC,
    dc_admin_pw:          pick(od.pass, s.pass, 'Asdf1234!'),
    win_timezone:         s.tz || 'W. Europe Standard Time',
    dc_dns_zones:         JSON.stringify(ac.dnsZones || []),
    dc_dhcp_scopes:       JSON.stringify(ac.dhcpScopes || []),
    dc_dhcp_failover:     !!ac.dhcpFailover,
    dc_failover_partner:  failVm?.ip || '',
    dc_enable_repl:       !!ac.enableRepl,
    dc_repl_partner_ip:   partnerVm?.ip || '',
  };
  const safeUser = req.session.username.replace(/[^a-z0-9_]/gi, '_');
  const evFile   = path.join(ADIR, 'inventory', `_ad_ev_${safeUser}.json`);
  const invFile  = path.join(ADIR, 'inventory', `_ad_inv_${safeUser}.ini`);
  fs.writeFileSync(evFile, JSON.stringify(adVars));
  fs.writeFileSync(invFile,
    `[dc]
${vm.hostname} ansible_host=${vm.ip}

[dc:vars]
` +
    `ansible_user=Administrator
ansible_password=${adVars.dc_admin_pw}
` +
    `ansible_connection=winrm
ansible_winrm_transport=basic
` +
    `ansible_winrm_port=5985
ansible_winrm_server_cert_validation=ignore
` +
    `ansible_winrm_scheme=http
`
  );
  const session = getOrInitDeploy(req.session.username);
  if (session.running) return res.status(409).json({ error: 'A deploy is already running for your account' });
  session.running = true; session.exitCode = 0;
  session.startedAt = new Date().toISOString();
  session.orgId = h.orgId; session.orgName = org?.name || '';
  session.vms   = [{ hostname: vm.hostname, ip: vm.ip, role: 'dc' }];
  session.log   = `[AD Setup] Starting on ${vm.hostname} (${vm.ip})
`;
  persistDeploys();
  res.json({ success: true });
  const apBin = `$(python3 -c "import shutil; print(shutil.which('ansible-playbook') or '/usr/local/bin/ansible-playbook')")`;
  const cmd = `cd "${ADIR}" && ${apBin} ad_setup.yml -i inventory/_ad_inv_${safeUser}.ini -e "@inventory/_ad_ev_${safeUser}.json" 2>&1`;
  const proc = exec(cmd);
  session.proc = proc;
  let ft = null; const flush = () => persistDeploys();
  proc.stdout?.on('data', d => { session.log += d; clearTimeout(ft); ft = setTimeout(flush, 500); });
  proc.stderr?.on('data', d => { session.log += d; clearTimeout(ft); ft = setTimeout(flush, 500); });
  proc.on('close', code => {
    session.running = false; session.proc = null; session.exitCode = code;
    session.log += `
[AD Setup] Finished with exit code ${code}
`;
    persistDeploys();
    appendHistory({ startedAt: session.startedAt, finishedAt: new Date().toISOString(),
      startedBy: req.session.username, orgId: h.orgId, orgName: org?.name||'',
      exitCode: code, vmCount: 1, vms: [{ hostname: vm.hostname, ip: vm.ip, role: 'dc' }] });
    try { fs.unlinkSync(evFile); fs.unlinkSync(invFile); } catch(_) {}
  });
});

// ── Static + catch-all ──────────────────────────────────────────────────────
app.use(express.static(path.join(__dirname, '../frontend')));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, '../frontend/index.html')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`windows-deployment → http://0.0.0.0:${PORT}`));
JS_EOF

  echo '{"name":"windows-deployment","version":"1.0.0","main":"server.js","scripts":{"start":"node server.js"},"dependencies":{"express":"^4.18.2","cors":"^2.8.5","cookie-parser":"^1.4.6","bcryptjs":"^2.4.3"}}' > "${DIR}/backend/package.json"

  # ---------------------------------------------------------------------------
  # ansible/ansible.cfg
  # ---------------------------------------------------------------------------
  cat > "${DIR}/ansible/ansible.cfg" << 'EOF'
[defaults]
inventory           = inventory/hosts.ini
roles_path          = roles
collections_paths   = ./collections
host_key_checking   = False
stdout_callback     = default
result_format       = yaml
timeout             = 60
deprecation_warnings = False
EOF

  # ---------------------------------------------------------------------------
  # ansible/site.yml
  # ---------------------------------------------------------------------------
  cat > "${DIR}/ansible/site.yml" << 'EOF'
---
# Phase 1: Clone VMs on Proxmox (runs on localhost, uses proxmoxer)
- name: Provision VMs on Proxmox
  hosts: localhost
  gather_facts: false
  roles: [proxmox_provision]

# Phase 2: Base config on every VM (hostname, timezone, DNS, RDP)
- name: Base config
  hosts: windows
  gather_facts: false
  roles: [common]

# Phase 3: Role-specific feature install
- name: Domain Controller
  hosts: dc
  gather_facts: false
  roles: [dc]

# Phase 4: AD Post-Setup on DC (runs after DC role, before other servers)
# Other servers wait for this so they can join the domain
- name: AD Post-Setup
  hosts: dc
  gather_facts: false
  roles: [ad_setup]

- name: File Server
  hosts: fileserver
  gather_facts: false
  roles: [fileserver]

- name: Backup Server
  hosts: backupserver
  gather_facts: false
  roles: [backupserver]

- name: RDS Connection Broker
  hosts: rds_broker
  gather_facts: false
  roles: [rds_broker]

- name: RDS Session Hosts
  hosts: rds_sessionhost
  gather_facts: false
  roles: [rds_sessionhost]

- name: Print Server
  hosts: printserver
  gather_facts: false
  roles: [printserver]

- name: Management Server
  hosts: mgmt
  gather_facts: false
  roles: [mgmt]
EOF

  # ---------------------------------------------------------------------------
  # ansible/group_vars/all.yml
  # ---------------------------------------------------------------------------
  cat > "${DIR}/ansible/group_vars/all.yml" << 'EOF'
# Defaults — all overridden at runtime via _extra_vars.json
ansible_user: Administrator
ansible_connection: winrm
ansible_winrm_transport: basic
ansible_winrm_port: 5985
ansible_winrm_server_cert_validation: ignore
ansible_winrm_scheme: http
network_gateway: "172.16.10.1"
network_prefix_length: 24
dns_primary: "8.8.8.8"
dns_secondary: "8.8.4.4"
win_timezone: "W. Europe Standard Time"
win_locale: "de-CH"
proxmox_host: "192.168.1.2"
proxmox_node: "pve"
proxmox_template_name: "win2025-template"
proxmox_storage: "local-lvm"
proxmox_bridge: "vmbr0"
EOF

  # ── ansible/ad_setup.yml ────────────────────────────────────────────────────
  cat > "${DIR}/ansible/ad_setup.yml" << 'ADEOF'
---
- name: AD Post-Setup
  hosts: dc
  gather_facts: no
  tasks:

    - name: Wait for WinRM
      ansible.builtin.wait_for_connection:
        timeout: 300

    - name: Install AD DS and DNS roles
      ansible.builtin.raw: >
        Install-WindowsFeature AD-Domain-Services,DNS,RSAT-AD-Tools,RSAT-DNS-Server,GPMC -IncludeManagementTools

    - name: Promote as primary DC (new forest)
      ansible.builtin.raw: |
        Import-Module ADDSDeployment
        Install-ADDSForest `
          -DomainName "{{ dc_domain }}" `
          -DomainNetbiosName "{{ dc_netbios }}" `
          -ForestMode "{{ dc_forest_mode }}" `
          -DomainMode "{{ dc_forest_mode }}" `
          -SafeModeAdministratorPassword (ConvertTo-SecureString "{{ dc_safe_mode_pw }}" -AsPlainText -Force) `
          -InstallDns `
          -Force `
          -NoRebootOnCompletion
      when: dc_is_primary | bool
      ignore_errors: yes

    - name: Promote as secondary DC
      ansible.builtin.raw: |
        Import-Module ADDSDeployment
        Install-ADDSDomainController `
          -DomainName "{{ dc_domain }}" `
          -SafeModeAdministratorPassword (ConvertTo-SecureString "{{ dc_safe_mode_pw }}" -AsPlainText -Force) `
          -Credential (New-Object PSCredential("{{ dc_netbios }}\Administrator",(ConvertTo-SecureString "{{ dc_admin_pw }}" -AsPlainText -Force))) `
          -Force `
          -NoRebootOnCompletion
      when: not (dc_is_primary | bool)
      ignore_errors: yes

    - name: Reboot after promotion
      ansible.builtin.raw: Restart-Computer -Force
      ignore_errors: yes

    - name: Wait for DC to come back
      ansible.builtin.wait_for_connection:
        delay: 60
        timeout: 300

    - name: Create additional DNS forward zones
      ansible.builtin.raw: |
        $zones = '{{ dc_dns_zones }}' | ConvertFrom-Json
        foreach ($z in $zones) {
          if ($z -and -not (Get-DnsServerZone -Name $z -ErrorAction SilentlyContinue)) {
            Add-DnsServerPrimaryZone -Name $z -ReplicationScope Domain
            Write-Host "Created DNS zone: $z"
          }
        }
      ignore_errors: yes

    - name: Create reverse lookup zone
      ansible.builtin.raw: |
        $octets = "{{ dc_ip }}".Split('.')
        $revNet = "$($octets[2]).$($octets[1]).$($octets[0]).in-addr.arpa"
        $netId  = "$($octets[0]).$($octets[1]).$($octets[2]).0/24"
        if (-not (Get-DnsServerZone -Name $revNet -ErrorAction SilentlyContinue)) {
          Add-DnsServerPrimaryZone -NetworkId $netId -ReplicationScope Domain
          Write-Host "Created reverse zone: $revNet"
        }
      ignore_errors: yes

    - name: Install and authorize DHCP
      ansible.builtin.raw: |
        Install-WindowsFeature DHCP,RSAT-DHCP -IncludeManagementTools
        Add-DhcpServerInDC -DnsName "{{ dc_hostname }}.{{ dc_domain }}" -IPAddress "{{ dc_ip }}"
      ignore_errors: yes

    - name: Create DHCP scopes
      ansible.builtin.raw: |
        $scopes = '{{ dc_dhcp_scopes }}' | ConvertFrom-Json
        $i = 1
        foreach ($sc in $scopes) {
          if (-not $sc.start -or -not $sc.end) { $i++; continue }
          $bits  = [int]$sc.pfx
          $mask  = ([string]([System.Net.IPAddress]([UInt32]::MaxValue -shl (32-$bits) -band [UInt32]::MaxValue))).ToString()
          $sid   = ($sc.start -replace '(\d+\.\d+\.\d+)\.\d+','$1.0')
          Add-DhcpServerv4Scope -Name "Scope $i" -StartRange $sc.start -EndRange $sc.end `
            -SubnetMask $mask -State Active -LeaseDuration ([TimeSpan]::FromDays([int]$sc.lease))
          if ($sc.gw) { Set-DhcpServerv4OptionValue -ScopeId $sid -Router $sc.gw }
          Set-DhcpServerv4OptionValue -ScopeId $sid -DnsServer "{{ dc_ip }}" -DnsDomain "{{ dc_domain }}"
          Write-Host "Created DHCP scope $i: $($sc.start) - $($sc.end)"
          $i++
        }
      when: dc_dhcp_scopes != '[]'
      ignore_errors: yes

    - name: Configure DHCP failover
      ansible.builtin.raw: |
        $scopes = Get-DhcpServerv4Scope | Select-Object -ExpandProperty ScopeId
        foreach ($sid in $scopes) {
          Add-DhcpServerv4Failover -Name "FO-$sid" -PartnerServer "{{ dc_failover_partner }}" `
            -ScopeId $sid -LoadBalancePercent 50 `
            -MaxClientLeadTime (New-TimeSpan -Hours 1) -Force
          Write-Host "Failover configured for scope $sid"
        }
      when: dc_dhcp_failover | bool and dc_failover_partner != ""
      ignore_errors: yes
ADEOF


  # ---------------------------------------------------------------------------
  # ROLE: proxmox_provision
  # ---------------------------------------------------------------------------
  # Write proxmox_provision tasks via python to guarantee correct YAML indentation.
  # IMPORTANT: The shell blocks use only bash/awk for VMID lookup — no inline Python —
  # because Ansible parses the YAML *before* the shell runs, and "import sys, json"
  # looks like a broken YAML key, causing "could not find expected ':'" errors.
  python3 /dev/stdin << 'PYEOF'
content = r"""---
- name: Install proxmoxer Python library
  ansible.builtin.pip:
    name:
      - proxmoxer
      - requests
    state: present
    extra_args: "--break-system-packages"

# Use a local Python script to clone via proxmoxer directly.
# community.proxmox.proxmox_kvm clone is unreliable — it searches by name
# but does not find templates on all Proxmox versions.
- name: Clone all VMs via proxmoxer Python script
  ansible.builtin.script: "{{ playbook_dir }}/pve_clone.py"
  args:
    executable: python3
  environment:
    PVE_HOST:          "{{ proxmox_host }}"
    PVE_TOKEN_ID:      "{{ proxmox_token_id }}"
    PVE_TOKEN_SECRET:  "{{ proxmox_token_secret }}"
    PVE_NODE:          "{{ proxmox_node }}"
    PVE_TEMPLATE_NAME: "{{ proxmox_template_name }}"
    PVE_STORAGE:       "{{ proxmox_storage }}"
    PVE_SERVERS:       "{{ servers | to_json }}"
    NET_PREFIX_LEN:    "{{ network_prefix_length }}"
    NET_GATEWAY:       "{{ network_gateway }}"
    DNS_PRIMARY:       "{{ dns_primary }}"
    WIN_PASS:          "{{ win_admin_pass }}"
    VMID_FILE:         "{{ vmid_file | default('') }}"
  delegate_to: localhost

- name: Wait for WinRM on all VMs (polls every 10s, no hardcoded sleep)
  ansible.builtin.wait_for:
    host:    "{{ item.ip }}"
    port:    5985
    timeout: 900
    delay:   10
  loop: "{{ servers }}"
  loop_control:
    label: "{{ item.hostname }}"
  delegate_to: localhost
"""
import os
path = "/opt/windows-deployment/ansible/roles/proxmox_provision/tasks/main.yml"
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    f.write(content)
print("proxmox_provision/tasks/main.yml written OK")
PYEOF

  # ---------------------------------------------------------------------------
  # Write all Ansible role task files via Python — zero collections needed,
  # all tasks use only ansible.builtin.raw which is built into Ansible core.
  # Write /tmp/write_roles.py then execute it — avoids all heredoc/quoting issues
  cat > /tmp/write_roles.py << 'ROLESCRIPT'
import os

BASE = "/opt/windows-deployment/ansible/roles"

common_yaml = (
    "---\n"
    "- name: Wait for WinRM\n"
    "  ansible.builtin.wait_for:\n"
    "    host:    '{{ ansible_host }}'\n"
    "    port:    5985\n"
    "    timeout: 600\n"
    "    delay:   30\n"
    "  delegate_to: localhost\n"
    "\n"
    "- name: Configure WinRM, hostname, timezone, DNS, RDP\n"
    "  ansible.builtin.raw: |\n"
    "    $ErrorActionPreference = 'Stop'\n"
    "    $needReboot = $false\n"
    "    winrm quickconfig -q -force 2>$null\n"
    "    $cfg = '@{AllowUnencrypted=' + [char]34 + 'true' + [char]34 + '}'\n"
    "    winrm set winrm/config/service $cfg 2>$null\n"
    "    $auth = '@{Basic=' + [char]34 + 'true' + [char]34 + '}'\n"
    "    winrm set winrm/config/service/auth $auth 2>$null\n"
    "    Set-Service WinRM -StartupType Automatic\n"
    "    Start-Service WinRM -ErrorAction SilentlyContinue\n"
    "    $desired = '{{ inventory_hostname_short }}'\n"
    "    if ($env:COMPUTERNAME -ne $desired) {\n"
    "      Rename-Computer -NewName $desired -Force\n"
    "      $needReboot = $true\n"
    "    }\n"
    "    Set-TimeZone -Id '{{ win_timezone }}'\n"
    "    $dns = @('{{ dns_primary }}', '{{ dns_secondary }}')\n"
    "    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {\n"
    "      Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses $dns\n"
    "    }\n"
    "    Set-ItemProperty 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' fDenyTSConnections 0\n"
    "    Enable-NetFirewallRule -DisplayName 'Remote Desktop*' -ErrorAction SilentlyContinue\n"
    "    if ($needReboot) { Restart-Computer -Force }\n"
    "\n"
    "- name: Wait for reboot\n"
    "  ansible.builtin.wait_for:\n"
    "    host:    '{{ ansible_host }}'\n"
    "    port:    5985\n"
    "    timeout: 300\n"
    "    delay:   30\n"
    "  delegate_to: localhost\n"
)

p = os.path.join(BASE, "common/tasks/main.yml")
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as fh:
    fh.write(common_yaml)
print("  wrote: common/tasks/main.yml")

ROLES = [
("dc/tasks/main.yml", [
"---",
"- name: Install Domain Controller features",
"  ansible.builtin.raw: |",
"    $f = @('AD-Domain-Services','DNS','DHCP','GPMC','RSAT-AD-Tools','RSAT-AD-PowerShell','RSAT-DNS-Server','RSAT-DHCP')",
"    $r = Install-WindowsFeature -Name $f -IncludeManagementTools",
"    if ($r.RestartNeeded -eq 'Yes') { Restart-Computer -Force }",
"",
"- name: Wait after DC install",
"  ansible.builtin.wait_for:",
"    host:    '{{ ansible_host }}'",
"    port:    5985",
"    timeout: 600",
"    delay:   60",
"  delegate_to: localhost",
]),
("fileserver/tasks/main.yml", [
"---",
"- name: Install File Server features",
"  ansible.builtin.raw: |",
"    Install-WindowsFeature -Name FS-FileServer,FS-DFS-Namespace,FS-DFS-Replication,FS-Resource-Manager,RSAT-DFS-Mgmt-Con -IncludeManagementTools",
]),
("backupserver/tasks/main.yml", [
"---",
"- name: Backup server ready",
"  ansible.builtin.debug:",
"    msg: 'Backup server ready - install backup software manually'",
]),
("rds_broker/tasks/main.yml", [
"---",
"- name: Install RDS Broker features",
"  ansible.builtin.raw: |",
"    $r = Install-WindowsFeature -Name RDS-Connection-Broker,RDS-Licensing,RDS-Web-Access,RSAT-RDS-Tools -IncludeManagementTools",
"    if ($r.RestartNeeded -eq 'Yes') { Restart-Computer -Force }",
"",
"- name: Wait after RDS Broker install",
"  ansible.builtin.wait_for:",
"    host:    '{{ ansible_host }}'",
"    port:    5985",
"    timeout: 600",
"    delay:   60",
"  delegate_to: localhost",
]),
("rds_sessionhost/tasks/main.yml", [
"---",
"- name: Install RDS Session Host features",
"  ansible.builtin.raw: |",
"    $r = Install-WindowsFeature -Name RDS-RD-Server,Desktop-Experience -IncludeManagementTools",
"    if ($r.RestartNeeded -eq 'Yes') { Restart-Computer -Force }",
"",
"- name: Wait after Session Host install",
"  ansible.builtin.wait_for:",
"    host:    '{{ ansible_host }}'",
"    port:    5985",
"    timeout: 600",
"    delay:   90",
"  delegate_to: localhost",
]),
("printserver/tasks/main.yml", [
"---",
"- name: Install Print Server",
"  ansible.builtin.raw: |",
"    Install-WindowsFeature -Name Print-Server,RSAT-Print-Services -IncludeManagementTools",
"    Set-Service -Name Spooler -StartupType Automatic",
"    Start-Service -Name Spooler -ErrorAction SilentlyContinue",
"    netsh advfirewall firewall set rule group='File and Printer Sharing' new enable=Yes",
]),
("mgmt/tasks/main.yml", [
"---",
"- name: Install full RSAT suite",
"  ansible.builtin.raw: |",
"    $f = @('RSAT','RSAT-AD-Tools','RSAT-AD-PowerShell','RSAT-DNS-Server','RSAT-DHCP','RSAT-DFS-Mgmt-Con','RSAT-Print-Services','RSAT-RDS-Tools','GPMC')",
"    Install-WindowsFeature -Name $f -IncludeManagementTools",
]),
]

for rel_path, content_lines in ROLES:
    full_path = os.path.join(BASE, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as fh:
        fh.write("\n".join(content_lines) + "\n")
    print("  wrote: " + rel_path)

print("All role files written OK")
ROLESCRIPT
  python3 /tmp/write_roles.py

  # ---------------------------------------------------------------------------
  # pve_clone.py — called by proxmox_provision role
  # ---------------------------------------------------------------------------
  # ── ansible/roles/ad_setup/tasks/main.yml ────────────────────────────────────
  cat > "${DIR}/ansible/roles/ad_setup/tasks/main.yml" << 'ADEOF'
---
# AD Post-Setup — runs on Domain Controller after DC role, before other servers
# Variables come from serversJson (per-VM dc_* fields) via extra_vars

- name: Skip if not a DC or domain not configured
  meta: end_play
  when: hostvars[inventory_hostname].dc_domain is not defined or hostvars[inventory_hostname].dc_domain == ""

- name: Wait for WinRM
  ansible.builtin.wait_for_connection:
    timeout: 180

- name: Install AD DS, DNS, DHCP roles
  ansible.builtin.raw: >
    Install-WindowsFeature AD-Domain-Services,DNS,DHCP,RSAT-AD-Tools,RSAT-DNS-Server,RSAT-DHCP,GPMC -IncludeManagementTools

- name: Promote as primary DC (new forest)
  ansible.builtin.raw: |
    Import-Module ADDSDeployment
    Install-ADDSForest `
      -DomainName "{{ hostvars[inventory_hostname].dc_domain }}" `
      -DomainNetbiosName "{{ hostvars[inventory_hostname].dc_netbios }}" `
      -ForestMode "{{ hostvars[inventory_hostname].dc_forest_mode }}" `
      -DomainMode "{{ hostvars[inventory_hostname].dc_forest_mode }}" `
      -SafeModeAdministratorPassword (ConvertTo-SecureString "{{ hostvars[inventory_hostname].dc_safe_mode_pw }}" -AsPlainText -Force) `
      -InstallDns -Force -NoRebootOnCompletion
  when: hostvars[inventory_hostname].dc_is_primary | bool
  ignore_errors: yes

- name: Promote as secondary DC
  ansible.builtin.raw: |
    Import-Module ADDSDeployment
    Install-ADDSDomainController `
      -DomainName "{{ hostvars[inventory_hostname].dc_domain }}" `
      -SafeModeAdministratorPassword (ConvertTo-SecureString "{{ hostvars[inventory_hostname].dc_safe_mode_pw }}" -AsPlainText -Force) `
      -Credential (New-Object PSCredential("{{ hostvars[inventory_hostname].dc_netbios }}\Administrator",(ConvertTo-SecureString "{{ win_admin_pass }}" -AsPlainText -Force))) `
      -Force -NoRebootOnCompletion
  when: not (hostvars[inventory_hostname].dc_is_primary | bool)
  ignore_errors: yes

- name: Reboot after promotion
  ansible.builtin.raw: Restart-Computer -Force
  ignore_errors: yes

- name: Wait for DC to come back online
  ansible.builtin.wait_for_connection:
    delay: 90
    timeout: 300

- name: Create reverse DNS zone
  ansible.builtin.raw: |
    $octets = "{{ hostvars[inventory_hostname].dc_ip | default(ansible_host) }}".Split('.')
    $netId  = "$($octets[0]).$($octets[1]).$($octets[2]).0/24"
    $revZone = "$($octets[2]).$($octets[1]).$($octets[0]).in-addr.arpa"
    if (-not (Get-DnsServerZone -Name $revZone -ErrorAction SilentlyContinue)) {
      Add-DnsServerPrimaryZone -NetworkId $netId -ReplicationScope Domain
      Write-Host "Created reverse zone: $revZone"
    }
  ignore_errors: yes

- name: Create additional DNS zones
  ansible.builtin.raw: |
    $zones = '{{ hostvars[inventory_hostname].dc_dns_zones | default("[]") }}' | ConvertFrom-Json
    foreach ($z in $zones) {
      if ($z -and -not (Get-DnsServerZone -Name $z -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $z -ReplicationScope Domain
        Write-Host "Created DNS zone: $z"
      }
    }
  ignore_errors: yes

- name: Authorize DHCP server in AD
  ansible.builtin.raw: |
    Add-DhcpServerInDC -DnsName "{{ inventory_hostname }}.{{ hostvars[inventory_hostname].dc_domain }}" -IPAddress "{{ hostvars[inventory_hostname].dc_ip | default(ansible_host) }}"
  ignore_errors: yes

- name: Create DHCP scopes
  ansible.builtin.raw: |
    $scopes = '{{ hostvars[inventory_hostname].dc_dhcp_scopes | default("[]") }}' | ConvertFrom-Json
    $i = 1
    foreach ($sc in $scopes) {
      if (-not $sc.start -or -not $sc.end) { $i++; continue }
      $bits = [int]($sc.pfx -replace '[^0-9]','24')
      $mask = ([Net.IPAddress]([UInt32]::MaxValue -shl (32-$bits) -band [UInt32]::MaxValue)).ToString()
      $sid  = ($sc.start -replace '(\d+\.\d+\.\d+)\.\d+','$1.0')
      Add-DhcpServerv4Scope -Name "Scope $i" -StartRange $sc.start -EndRange $sc.end -SubnetMask $mask -State Active -LeaseDuration ([TimeSpan]::FromDays([int]($sc.lease -replace '[^0-9]','8')))
      if ($sc.gw) { Set-DhcpServerv4OptionValue -ScopeId $sid -Router $sc.gw }
      Set-DhcpServerv4OptionValue -ScopeId $sid -DnsServer "{{ hostvars[inventory_hostname].dc_ip | default(ansible_host) }}" -DnsDomain "{{ hostvars[inventory_hostname].dc_domain }}"
      Write-Host "Created DHCP scope $i: $($sc.start)-$($sc.end)"
      $i++
    }
  when: hostvars[inventory_hostname].dc_dhcp_scopes | default('[]') != '[]'
  ignore_errors: yes

- name: Configure DHCP failover
  ansible.builtin.raw: |
    $scopes = Get-DhcpServerv4Scope | Select-Object -ExpandProperty ScopeId
    foreach ($sid in $scopes) {
      Add-DhcpServerv4Failover -Name "FO-$sid" -PartnerServer "{{ hostvars[inventory_hostname].dc_failover_ip }}" -ScopeId $sid -LoadBalancePercent 50 -MaxClientLeadTime (New-TimeSpan -Hours 1) -Force
    }
  when: hostvars[inventory_hostname].dc_dhcp_failover | bool and hostvars[inventory_hostname].dc_failover_ip | default('') != ''
  ignore_errors: yes
ADEOF

  cat > "${DIR}/ansible/pve_clone.py" << 'PYCLONE'
#!/usr/bin/env python3
import os, sys, json, time, threading
from proxmoxer import ProxmoxAPI

host          = os.environ['PVE_HOST']
token_id      = os.environ['PVE_TOKEN_ID']
token_secret  = os.environ['PVE_TOKEN_SECRET']
node          = os.environ['PVE_NODE']
template_name = os.environ['PVE_TEMPLATE_NAME']
storage       = os.environ['PVE_STORAGE']
servers       = json.loads(os.environ['PVE_SERVERS'])
prefix_len    = os.environ['NET_PREFIX_LEN']
gateway       = os.environ['NET_GATEWAY']
dns           = os.environ['DNS_PRIMARY']
win_pass      = os.environ['WIN_PASS']
vmid_file     = os.environ.get('VMID_FILE', '')  # path to write created VMIDs for rollback

if '!' in token_id:
    api_user, token_name = token_id.split('!', 1)
else:
    api_user, token_name = 'root@pam', token_id

log_lock      = threading.Lock()
vmid_lock     = threading.Lock()
errors        = []
created_vmids = []  # track all VMIDs created, written to vmid_file for abort/rollback

def record_vmid(vmid):
    """Append a newly created VMID to the tracking file for abort/rollback."""
    with vmid_lock:
        created_vmids.append(vmid)
        if vmid_file:
            try:
                with open(vmid_file, 'w') as f:
                    json.dump(created_vmids, f)
            except Exception:
                pass

def log(msg):
    with log_lock:
        print(f'[{time.strftime("%H:%M:%S")}] {msg}', flush=True)

def wait_task(px, upid, label, timeout=None):
    """Poll task until stopped. Shows elapsed time + ETA. timeout=None means wait forever."""
    start   = time.time()
    # Parse node from UPID: UPID:nodename:...
    task_node = upid.split(':')[1] if ':' in upid else node
    prev_pct  = -1
    prev_log  = 0
    while True:
        elapsed = time.time() - start
        if timeout is not None and elapsed > timeout:
            raise TimeoutError(f'{label}: timed out after {timeout}s')
        try:
            s = px.nodes(task_node).tasks(upid).status.get()
        except Exception as e:
            log(f'  {label}: poll error ({e}), retrying...')
            time.sleep(5)
            continue
        if s['status'] == 'stopped':
            exitcode = s.get('exitstatus', '')
            if exitcode != 'OK':
                raise RuntimeError(f'{label} failed: {exitcode}')
            log(f'  {label}: finished in {elapsed:.0f}s')
            return elapsed
        # Progress reporting
        pct = s.get('pct', 0) or 0
        now = time.time()
        if pct > 0 and pct != prev_pct:
            eta = (elapsed / pct) * (100 - pct)
            log(f'  {label}: {pct:.0f}%  elapsed={elapsed:.0f}s  ETA~{eta:.0f}s')
            prev_pct = pct
            prev_log = now
        elif pct == 0 and now - prev_log >= 15:
            log(f'  {label}: running... {elapsed:.0f}s elapsed (no progress info)')
            prev_log = now
        time.sleep(2)

def wait_running(px, vmid, label, timeout=300):
    """Poll VM status until running. No hardcoded sleep."""
    start = time.time()
    while time.time() - start < timeout:
        try:
            st = px.nodes(node).qemu(vmid).status.current.get()
            status = st.get('qmpstatus') or st.get('status', '')
            if status == 'running':
                log(f'  {label}: running (boot confirmed in {time.time()-start:.0f}s)')
                return
        except Exception:
            pass
        time.sleep(3)
    log(f'  {label}: WARNING - did not confirm running within {timeout}s')

def clone_vm(srv):
    hostname = srv['hostname']
    ip, cpus, ram, disk_gb = srv['ip'], srv['cpus'], srv['ram'], srv['disk']
    try:
        current = px.nodes(node).qemu.get()
        existing = next((v for v in current if v['name'] == hostname), None)
        if existing:
            vmid = existing['vmid']
            log(f'{hostname}: already exists VMID={vmid}, skipping clone')
        else:
            with vmid_lock:
                vmid = int(px.cluster.nextid.get())
                log(f'{hostname}: cloning template {template_vmid} -> VMID {vmid}')
                upid = px.nodes(node).qemu(template_vmid).clone.post(
                    newid=vmid, name=hostname, full=1, storage=storage)
            wait_task(px, upid, f'{hostname} clone')
            record_vmid(vmid)

        # ── All config while VM is STOPPED ────────────────────────────────────
        px.nodes(node).qemu(vmid).config.post(cores=int(cpus), memory=int(ram))

        try:
            upid_r = px.nodes(node).qemu(vmid).resize.put(disk='scsi0', size=f'{disk_gb}G')
            if isinstance(upid_r, str) and upid_r.startswith('UPID'):
                wait_task(px, upid_r, f'{hostname} resize')
            log(f'  {hostname}: disk -> {disk_gb}G')
        except Exception as e:
            log(f'  {hostname}: disk resize skipped ({e})')

        # ── Cloud-Init setup ───────────────────────────────────────────────────
        # Proxmox Cloud-Init for Windows works like this:
        #   1. A cloud-init drive (ISO) is attached to the VM
        #   2. Proxmox writes config to that ISO (ip, password, etc.)
        #   3. Cloudbase-Init reads the ISO on first boot and applies settings
        #   4. The ISO must be REGENERATED after setting params, before boot
        #
        # The regeneration API endpoint: POST /nodes/{node}/qemu/{vmid}/cloudinit
        # proxmoxer: px.nodes(node).qemu(vmid).cloudinit.post() -- but this is
        # not always available. Reliable fallback: use the Proxmox task API
        # via a node execute command.

        cfg = px.nodes(node).qemu(vmid).config.get()
        log(f'  {hostname}: config keys = {sorted(cfg.keys())}')

        # Check for existing cloud-init drive
        ci_drive = next((k for k, v in cfg.items()
                         if k.startswith(('ide','sata','scsi','virtio'))
                         and 'cloudinit' in str(v).lower()), None)

        if not ci_drive:
            # Find a free IDE slot (ide0/ide1 may be used by CDROMs)
            used = set(cfg.keys())
            free_ide = next((f'ide{n}' for n in range(4) if f'ide{n}' not in used), 'ide2')
            log(f'  {hostname}: adding cloud-init drive on {free_ide}')
            try:
                px.nodes(node).qemu(vmid).config.post(**{free_ide: f'{storage}:cloudinit'})
                ci_drive = free_ide
            except Exception as e:
                log(f'  {hostname}: WARNING cloud-init drive error: {e}')
        else:
            log(f'  {hostname}: cloud-init drive on {ci_drive}')

        # Write Cloud-Init parameters
        px.nodes(node).qemu(vmid).config.put(
            ipconfig0=f'ip={ip}/{prefix_len},gw={gateway}',
            nameserver=dns,
            cipassword=win_pass,
            ciuser='Administrator',
        )

        # Verify written
        cfg2 = px.nodes(node).qemu(vmid).config.get()
        log(f'  {hostname}: ipconfig0 = {cfg2.get("ipconfig0","NOT SET")}')
        log(f'  {hostname}: cipassword set = {"cipassword" in cfg2}')

        # Regenerate Cloud-Init ISO via Proxmox node execute
        # This is equivalent to running "qm cloudinit update <vmid>" on the node
        log(f'  {hostname}: regenerating cloud-init ISO via node execute...')
        try:
            # Try proxmoxer's cloudinit endpoint first (Proxmox 7.x+)
            upid_ci = px.nodes(node).qemu(vmid).cloudinit.put()
            if isinstance(upid_ci, str) and upid_ci.startswith('UPID'):
                wait_task(px, upid_ci, f'{hostname} cloudinit-regen')
            log(f'  {hostname}: cloud-init ISO regenerated OK')
        except Exception as e1:
            log(f'  {hostname}: cloudinit.put() not available ({e1}), trying execute...')
            try:
                # Fallback: run qm cloudinit update via node execute API
                upid_exec = px.nodes(node).execute.post(
                    command=f'qm cloudinit update {vmid}')
                if isinstance(upid_exec, str) and upid_exec.startswith('UPID'):
                    wait_task(px, upid_exec, f'{hostname} cloudinit-exec')
                log(f'  {hostname}: cloud-init ISO regenerated via execute OK')
            except Exception as e2:
                log(f'  {hostname}: WARNING both regen methods failed: {e2}')
                log(f'  {hostname}: Cloud-Init ISO may have stale data!')

        # ── Start VM ──────────────────────────────────────────────────────────
        log(f'  {hostname}: starting VM...')
        upid_start = px.nodes(node).qemu(vmid).status.start.post()
        if isinstance(upid_start, str) and upid_start.startswith('UPID'):
            wait_task(px, upid_start, f'{hostname} start')
        wait_running(px, vmid, hostname)
        log(f'{hostname}: DONE — VMID={vmid} ip={ip}')
        log(f'{hostname}: NOTE — Cloudbase-Init will set hostname/IP/pass on first boot.')
        log(f'{hostname}: WinRM available after ~5-10min (OOBE + Cloudbase-Init).')

    except Exception as e:
        log(f'{hostname}: ERROR - {e}')
        with log_lock:
            errors.append((hostname, str(e)))


log(f'Connecting to {host} as {api_user} token={token_name}')
px = ProxmoxAPI(host, user=api_user, token_name=token_name,
                token_value=token_secret, verify_ssl=False)

all_vms = px.nodes(node).qemu.get()
tmpl    = next((v for v in all_vms if v['name'] == template_name), None)
if not tmpl:
    log(f"ERROR: Template '{template_name}' not found on node {node}.")
    log(f'Available: {sorted(v["name"] for v in all_vms)}')
    sys.exit(1)
template_vmid = tmpl['vmid']
log(f"Template '{template_name}' = VMID {template_vmid}")
log(f'Starting parallel clone of {len(servers)} VM(s)...')

t0      = time.time()
threads = [threading.Thread(target=clone_vm, args=(s,), daemon=True) for s in servers]
for t in threads: t.start()
for t in threads: t.join()

log(f'All threads done in {time.time()-t0:.0f}s')
if errors:
    log('ERRORS:')
    for h, e in errors:
        log(f'  {h}: {e}')
    sys.exit(1)
log('All VMs cloned, configured and started OK')
PYCLONE

  # pve_cleanup.py — deletes VMIDs from Proxmox via API token (called on abort)
  cat > "${DIR}/ansible/pve_cleanup.py" << 'PYCLEANUP'
#!/usr/bin/env python3
import sys, json, time
from proxmoxer import ProxmoxAPI

if len(sys.argv) < 6:
    print('Usage: pve_cleanup.py HOST TOKEN_ID TOKEN_SECRET NODE VMID1,VMID2,...')
    sys.exit(1)

host, token_id, token_secret, node = sys.argv[1:5]
vmids = [int(v) for v in sys.argv[5].split(',') if v.strip()]

if '!' in token_id:
    api_user, token_name = token_id.split('!', 1)
else:
    api_user, token_name = 'root@pam', token_id

print(f'[cleanup] Connecting to {host} as {api_user}')
px = ProxmoxAPI(host, user=api_user, token_name=token_name,
                token_value=token_secret, verify_ssl=False)

def wait_task(upid, label, timeout=120):
    task_node = upid.split(':')[1] if ':' in upid else node
    start = time.time()
    while True:
        if timeout and time.time() - start > timeout:
            print(f'  {label}: timed out')
            return
        try:
            s = px.nodes(task_node).tasks(upid).status.get()
            if s['status'] == 'stopped':
                print(f'  {label}: done ({s.get("exitstatus","?")})')
                return
        except Exception:
            pass
        time.sleep(2)

for vmid in vmids:
    try:
        print(f'[cleanup] Stopping VMID {vmid}...')
        try:
            upid = px.nodes(node).qemu(vmid).status.stop.post()
            wait_task(upid, f'stop {vmid}')
        except Exception as e:
            print(f'  stop error (may already be stopped): {e}')
        print(f'[cleanup] Deleting VMID {vmid}...')
        upid = px.nodes(node).qemu(vmid).delete(purge=1)
        wait_task(upid, f'delete {vmid}')
        print(f'[cleanup] VMID {vmid} deleted OK')
    except Exception as e:
        print(f'[cleanup] ERROR on VMID {vmid}: {e}')

print('[cleanup] All done')
PYCLEANUP


  ok "All files written"
}

# =============================================================================
#  INSTALL
# =============================================================================
install() {
  banner; check_root; touch "$LOG"
  read -rp "$(echo -e "${BOLD}Port [${PORT}]: ${NC}")" _p; PORT="${_p:-$PORT}"
  echo -e "\n${BOLD}Will install:${NC} Node.js 20 · Ansible · Python deps · App on :${PORT}"
  read -rp "$(echo -e "${BOLD}Continue? [y/N]: ${NC}")" c
  [[ "${c,,}" =~ ^y ]] || { echo "Aborted."; exit 0; }

  sec "System packages"
  apt-get update -qq 2>&1 | tee -a "$LOG"
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl wget python3 python3-pip ca-certificates gnupg 2>&1 | tee -a "$LOG"
  ok "System packages"

  sec "Node.js 20"
  if ! node -e "process.exit(+process.versions.node.split('.')[0]<20?1:0)" 2>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >>"$LOG" 2>&1
    apt-get install -y -qq nodejs >>"$LOG" 2>&1
  fi
  ok "Node.js $(node --version)"

  sec "Ansible"
  # apt gibt Ansible 2.14 — zu alt. pip installiert aktuelle Version (2.17+).
  pip3 install --break-system-packages --upgrade ansible proxmoxer requests pywinrm >>"$LOG" 2>&1
  export PATH="$PATH:/usr/local/bin:$HOME/.local/bin"
  ANSIBLE_BIN=$(python3 -c "import shutil; print(shutil.which('ansible') or '/usr/local/bin/ansible')")
  inf "Ansible binary: ${ANSIBLE_BIN}"
  ${ANSIBLE_BIN} --version >>"$LOG" 2>&1
  # Collections direkt ins Projektverzeichnis installieren — kein PATH/systemd-Problem möglich
  GALAXY_BIN=$(python3 -c "import shutil; print(shutil.which('ansible-galaxy') or '/usr/local/bin/ansible-galaxy')")
  ${GALAXY_BIN} collection install \
    community.general \
    community.windows \
    ansible.windows \
    community.proxmox \
    -p "${DIR}/ansible/collections" >>"$LOG" 2>&1
  ok "Ansible + collections + Python deps"

  sec "Application"
  write_files
  cd "${DIR}/backend" && npm install --omit=dev >>"$LOG" 2>&1
  mkdir -p "${DIR}/backend/data" "${DIR}/ansible/inventory"
  ok "npm install"

  sec "systemd service"
  cat > "$SVC" << SVCEOF
[Unit]
Description=windows-deployment
After=network.target

[Service]
Type=simple
WorkingDirectory=${DIR}/backend
Environment=PORT=${PORT}
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=ANSIBLE_COLLECTIONS_PATHS=/usr/share/ansible/collections:/root/.ansible/collections
ExecStart=/usr/bin/node ${DIR}/backend/server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${APP}

[Install]
WantedBy=multi-user.target
SVCEOF
  systemctl daemon-reload
  systemctl enable "${APP}" >>"$LOG" 2>&1
  systemctl restart "${APP}"
  sleep 2
  systemctl is-active --quiet "${APP}" && ok "Service running" || inf "Check: journalctl -u ${APP} -n 20"

  command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q active && \
    ufw allow "${PORT}/tcp" comment "${APP}" >>"$LOG" 2>&1 && ok "UFW: port ${PORT} opened" || true

  IP=$(hostname -I | awk '{print $1}')
  echo -e "\n${BOLD}${GREEN}✓ Installation complete${NC}\n"
  echo -e "  ${BOLD}Web UI:${NC}    http://${IP}:${PORT}"
  echo -e "  ${BOLD}Logs:${NC}      journalctl -u ${APP} -f"
  echo ""
}

# =============================================================================
#  UNINSTALL
# =============================================================================
uninstall() {
  banner; check_root

  echo -e "${BOLD}${RED}This will completely remove:${NC}"
  echo -e "  • systemd service + unit file"
  echo -e "  • Application directory  ${BOLD}${DIR}${NC}"
  echo -e "  • Log file               ${BOLD}${LOG}${NC}"
  echo -e "  • npm packages           (node_modules inside ${DIR})"
  echo -e "  • pip packages           ansible · proxmoxer · pywinrm · requests"
  echo -e "  • Ansible collections    (inside ${DIR})"
  echo -e "  • UFW rule               port ${PORT}/tcp"
  echo -e ""
  echo -e "  ${YEL}Node.js itself is NOT removed (system package).${NC}"
  echo -e "  ${YEL}Proxmox VMs are NOT affected.${NC}"
  echo -e ""

  # Optional: offer data backup
  if [[ -d "${DIR}/backend/data" ]]; then
    read -rp "$(echo -e "${BOLD}Back up data files before removing? [Y/n]: ${NC}")" _bak
    _bak="${_bak:-Y}"
    if [[ "$_bak" =~ ^[Yy] ]]; then
      BAK="/tmp/${APP}-data-$(date +%Y%m%d-%H%M%S).tar.gz"
      tar -czf "$BAK" -C "${DIR}/backend" data 2>/dev/null && ok "Data backed up → ${BAK}" || warn "Backup failed — continuing anyway"
    fi
  fi

  read -rp "$(echo -e "${BOLD}${RED}Type 'yes' to confirm full removal: ${NC}")" c
  [[ "$c" == "yes" ]] || { echo "Aborted."; exit 0; }
  echo ""

  # ── 1. Stop and remove systemd service ──────────────────────────────────────
  sec "systemd service"
  systemctl stop    "${APP}" 2>/dev/null && ok "Service stopped"   || true
  systemctl disable "${APP}" 2>/dev/null && ok "Service disabled"  || true
  if [[ -f "$SVC" ]]; then
    rm -f "$SVC"
    systemctl daemon-reload
    systemctl reset-failed 2>/dev/null || true
    ok "Unit file removed + daemon reloaded"
  else
    warn "Unit file not found (${SVC})"
  fi

  # ── 2. Remove application directory ─────────────────────────────────────────
  sec "Application files"
  if [[ -d "$DIR" ]]; then
    rm -rf "$DIR"
    ok "Removed: ${DIR}"
  else
    warn "Directory not found: ${DIR}"
  fi

  # ── 3. Remove log file ───────────────────────────────────────────────────────
  sec "Log file"
  if [[ -f "$LOG" ]]; then
    rm -f "$LOG"
    ok "Removed: ${LOG}"
  else
    warn "Log not found: ${LOG}"
  fi

  # ── 4. Remove pip packages ───────────────────────────────────────────────────
  sec "Python packages"
  PIP_PKGS=(ansible proxmoxer pywinrm requests)
  for pkg in "${PIP_PKGS[@]}"; do
    pip3 uninstall -y "$pkg" --break-system-packages 2>/dev/null && ok "pip: removed ${pkg}" || warn "pip: ${pkg} not found"
  done

  # ── 5. Remove ansible-related leftover files ─────────────────────────────────
  sec "Ansible leftovers"
  for candidate in \
    /usr/local/lib/python3*/dist-packages/ansible* \
    /usr/local/lib/python3*/dist-packages/proxmoxer* \
    /usr/local/lib/python3*/dist-packages/winrm* \
    ~/.ansible \
    /root/.ansible
  do
    if [[ -e "$candidate" ]]; then
      rm -rf "$candidate" && ok "Removed: ${candidate}" || warn "Could not remove: ${candidate}"
    fi
  done

  # ── 6. UFW firewall rule ─────────────────────────────────────────────────────
  sec "Firewall"
  if command -v ufw &>/dev/null; then
    ufw delete allow "${PORT}/tcp" 2>/dev/null && ok "UFW: rule for port ${PORT} removed" || warn "UFW: no rule found for port ${PORT}"
  else
    warn "UFW not installed — skipping"
  fi

  # ── 7. journald logs ─────────────────────────────────────────────────────────
  sec "Journal logs"
  journalctl --rotate 2>/dev/null || true
  journalctl --vacuum-time=1s --unit="${APP}" 2>/dev/null && ok "Journal entries cleared" || warn "Could not clear journal (non-fatal)"

  echo ""
  echo -e "${BOLD}${GREEN}✓ Fully uninstalled — system is clean.${NC}"
  echo -e "  Run ${BOLD}sudo bash setup.sh${NC} for a fresh install."
  [[ -n "${BAK:-}" ]] && echo -e "  Data backup: ${BOLD}${BAK}${NC}"
  echo ""
}

# =============================================================================
#  STATUS
# =============================================================================
status() {
  systemctl status "${APP}" --no-pager -l 2>/dev/null || echo "Not installed"
  echo ""
  journalctl -u "${APP}" -n 25 --no-pager 2>/dev/null
}

case "${1:-install}" in
  install)   install   ;;
  uninstall) uninstall ;;
  status)    status    ;;
  *) echo "Usage: sudo bash setup.sh [install|uninstall|status]"; exit 1 ;;
esac
