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
  mkdir -p "${DIR}"/{frontend,backend/data,ansible/{roles/{common,dc,fileserver,backupserver,rds_broker,rds_sessionhost,printserver,mgmt,proxmox_provision}/tasks,group_vars,inventory},docs}

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
  --text:#d4dff0;--text2:#7a91ae;--text3:#3d5470;
  --mono:'DM Mono',monospace;--sans:'DM Sans',sans-serif;
  --rad:3px;--rad2:5px;
}
html,body{height:100%;overflow:hidden}
body{background:var(--bg);color:var(--text);font-family:var(--sans);font-size:13px;display:flex;flex-direction:column}

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

#layout{display:flex;flex:1;overflow:hidden}

#sidebar{width:256px;flex-shrink:0;background:var(--panel);border-right:1px solid var(--b1);display:flex;flex-direction:column;overflow:hidden}
#sb-top{padding:8px;border-bottom:1px solid var(--b1);display:flex;gap:5px;align-items:center}
.sb-search{position:relative;flex:1}
.sb-search svg{position:absolute;left:7px;top:50%;transform:translateY(-50%);width:11px;height:11px;color:var(--text3);pointer-events:none}
#sb-input{width:100%;background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:5px 7px 5px 24px;border-radius:var(--rad);font-size:11.5px;font-family:var(--sans);outline:none;transition:border-color .12s}
#sb-input:focus{border-color:var(--amber)}#sb-input::placeholder{color:var(--text3)}
.sb-plus{width:26px;height:26px;background:var(--amber);color:#000;border:none;border-radius:var(--rad);cursor:pointer;font-size:17px;font-weight:700;line-height:1;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:opacity .12s}
.sb-plus:hover{opacity:.85}
#tree{flex:1;overflow-y:auto;padding:3px 0 8px;user-select:none}
#tree::-webkit-scrollbar{width:3px}#tree::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}

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

#dp{width:288px;flex-shrink:0;background:var(--panel);border-left:1px solid var(--b1);display:none;flex-direction:column;overflow:hidden}
#dp.open{display:flex}
.dp-head{padding:11px 13px;border-bottom:1px solid var(--b1);display:flex;align-items:center;gap:7px;flex-shrink:0}
.dp-hic{width:26px;height:26px;border-radius:var(--rad);display:flex;align-items:center;justify-content:center;font-size:13px;flex-shrink:0}
.dp-htitle{font-weight:600;font-size:13px}
.dp-hsub{font-size:10.5px;color:var(--text2);margin-top:1px}
.dp-x{margin-left:auto;background:none;border:none;color:var(--text3);cursor:pointer;font-size:15px;padding:2px 5px;border-radius:var(--rad);transition:all .1s;line-height:1}
.dp-x:hover{background:var(--panel2);color:var(--text)}
.dp-scroll{flex:1;overflow-y:auto}
.dp-scroll::-webkit-scrollbar{width:3px}
.dp-sec{padding:11px 13px;border-bottom:1px solid var(--b1)}
.dp-sec:last-child{border-bottom:none}
.dp-sec-title{font-size:9px;font-family:var(--mono);color:var(--text3);text-transform:uppercase;letter-spacing:.1em;font-weight:500;margin-bottom:7px}
.dp-row{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:4px}.dp-row:last-child{margin-bottom:0}
.dp-k{font-size:11.5px;color:var(--text2)}.dp-v{font-size:11.5px;font-family:var(--mono);text-align:right;max-width:155px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.dp-actions{padding:11px 13px;display:flex;flex-direction:column;gap:5px}

.btn{display:inline-flex;align-items:center;justify-content:center;gap:4px;padding:5px 12px;border-radius:var(--rad);font-family:var(--sans);font-size:12px;font-weight:500;cursor:pointer;transition:all .1s;border:1px solid transparent;text-decoration:none;white-space:nowrap}
.btn-a{background:var(--amber);color:#000;border-color:var(--amber)}.btn-a:hover{opacity:.9}
.btn-g{background:transparent;color:var(--text2);border-color:var(--b2)}.btn-g:hover{color:var(--text);background:var(--panel2);border-color:var(--b3)}
.btn-d{background:transparent;color:var(--red);border-color:rgba(240,80,80,.2)}.btn-d:hover{background:var(--red-d)}
.btn-dep{background:var(--green);color:#000;font-weight:600;font-family:var(--mono);font-size:11.5px;letter-spacing:.04em}.btn-dep:hover{filter:brightness(1.1)}.btn-dep:disabled{opacity:.3;cursor:not-allowed}
.btn-sm{padding:3px 9px;font-size:11px}.btn-fw{width:100%}

.ff{margin-bottom:9px}
.ff label{display:block;font-size:10.5px;color:var(--text2);margin-bottom:3px;font-weight:500;letter-spacing:.02em}
.ff input,.ff select{width:100%;background:var(--panel2);border:1px solid var(--b1);color:var(--text);padding:5px 8px;border-radius:var(--rad);font-size:12px;font-family:var(--sans);outline:none;transition:border-color .12s;appearance:none}
.ff input:focus,.ff select:focus{border-color:var(--amber)}
.ff input::placeholder{color:var(--text3)}
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
#log{background:#050810;border:1px solid var(--b1);border-radius:var(--rad);height:260px;overflow-y:auto;padding:9px 11px;font-family:var(--mono);font-size:10.5px;color:#4ade80;line-height:1.8;white-space:pre-wrap;word-break:break-all}
#log::-webkit-scrollbar{width:3px}#log::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}

.sep{height:1px;background:var(--b1);margin:7px 0}
.pill{display:inline-block;padding:1px 6px;border-radius:8px;font-size:9.5px;font-family:var(--mono);font-weight:500}
.empty{text-align:center;padding:36px 0;color:var(--text3)}.empty p{font-size:12px;margin-top:6px}

#deploy-status-bar{display:none;align-items:center;gap:8px;padding:6px 14px;background:var(--panel2);border-bottom:1px solid var(--b1);font-size:11px;font-family:var(--mono);color:var(--text2)}
#deploy-status-bar.visible{display:flex}
.dsb-dot{width:6px;height:6px;border-radius:50%;background:var(--amber);animation:blink .8s infinite;flex-shrink:0}

#modal-bg{position:fixed;inset:0;background:rgba(0,0,0,.65);display:none;align-items:center;justify-content:center;z-index:100;backdrop-filter:blur(2px)}
#modal-bg.open{display:flex}
#modal{background:var(--panel);border:1px solid var(--b2);border-radius:var(--rad2);width:440px;max-height:84vh;overflow-y:auto;box-shadow:0 20px 60px rgba(0,0,0,.7)}
#modal::-webkit-scrollbar{width:3px}#modal::-webkit-scrollbar-thumb{background:var(--b2);border-radius:2px}
.mhd{padding:12px 16px;border-bottom:1px solid var(--b1);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--panel);z-index:1}
.mhd h3{font-size:13px;font-weight:600}
.mbd{padding:16px}.mft{padding:9px 16px;border-top:1px solid var(--b1);display:flex;gap:5px;justify-content:flex-end;position:sticky;bottom:0;background:var(--panel)}

#toast{position:fixed;bottom:20px;right:20px;background:var(--red-d);border:1px solid var(--red);color:var(--text);padding:10px 14px;border-radius:var(--rad2);font-size:12px;font-family:var(--mono);z-index:999;display:none;max-width:360px;word-break:break-word}
#toast.show{display:block;animation:fi .2s ease}
</style>
</head>
<body>
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
    <button class="tnb" onclick="setView('settings',this)">Settings</button>
  </div>
  <div id="topbar-right">
    <div class="conn-pill"><div class="cdot off" id="cdot"></div><span id="clab">No hosts</span></div>
    <button class="btn btn-g btn-sm" onclick="openModal('host')">+ Add Host</button>
  </div>
</div>

<div id="layout">
<div id="sidebar">
  <div id="sb-top">
    <div class="sb-search">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      <input id="sb-input" placeholder="Filter…" autocomplete="off" oninput="renderTree(this.value.toLowerCase())">
    </div>
    <button class="sb-plus" onclick="openModal('vm')" title="Add VM">+</button>
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
      <button class="btn btn-g btn-sm" onclick="renderAll()">↺ Refresh</button>
      <button class="btn btn-a btn-sm" onclick="openModal('vm')">+ Add VM</button>
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
    <div class="ph-l"><div class="ph-title">Deploy</div><div class="ph-sub">Clone template VMs on Proxmox, apply network config, install Windows roles</div></div>
    <div class="ph-r"><button class="btn btn-dep" id="dep-btn" onclick="startDeploy()">⚡ Deploy All</button></div>
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
          <span id="live-b" style="margin-left:auto"></span>
        </div>
        <div class="sc-body" style="padding:7px 9px">
          <div id="log">// Add hosts and VMs, then click ⚡ Deploy All
// Each VM will be: cloned from template → static IP applied → RDP enabled → role features installed
</div>
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

<!-- SETTINGS -->
<div class="view" id="view-settings">
  <div class="ph">
    <div class="ph-l"><div class="ph-title">Settings</div><div class="ph-sub">Global defaults — applied to every new VM</div></div>
    <div class="ph-r"><button class="btn btn-a btn-sm" id="save-btn" onclick="saveSettings()">Save</button></div>
  </div>
  <div class="sg">
    <div class="sg-head">🌍 Network</div>
    <div class="sg-body">
      <div class="g3">
        <div class="ff"><label>Network prefix</label><input id="s-net" autocomplete="off" value="192.168.1"></div>
        <div class="ff"><label>Gateway</label><input id="s-gw" autocomplete="off" value="192.168.1.1"></div>
        <div class="ff"><label>Subnet</label><input type="number" id="s-pfx" autocomplete="off" value="24" min="8" max="30"></div>
      </div>
      <div class="g2">
        <div class="ff"><label>Primary DNS</label><input id="s-dns1" autocomplete="off" value="8.8.8.8"></div>
        <div class="ff"><label>Secondary DNS</label><input id="s-dns2" autocomplete="off" value="8.8.4.4"></div>
      </div>
    </div>
  </div>
  <div class="sg">
    <div class="sg-head">💻 Default VM Resources</div>
    <div class="sg-body">
      <div class="g3">
        <div class="ff"><label>CPUs</label><input type="number" id="s-cpus" autocomplete="off" value="2" min="1" max="64"></div>
        <div class="ff"><label>RAM (MB)</label><input type="number" id="s-ram" autocomplete="off" value="4096" step="1024"></div>
        <div class="ff"><label>Disk (GB)</label><input type="number" id="s-disk" autocomplete="off" value="75" min="40"></div>
      </div>
      <div class="ff"><label>Windows Administrator Password</label><input type="password" id="s-pass" autocomplete="new-password" value="ChangeMe123!"></div>
    </div>
  </div>
  <div class="sg">
    <div class="sg-head">🕐 Locale & Timezone</div>
    <div class="sg-body"><div class="g2">
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
    </div></div>
  </div>
</div>

</div>
<div id="dp"><div class="dp-scroll"><div id="dp-body"></div></div></div>
</div>
</div>

<div id="modal-bg" onclick="if(event.target===this)closeModal()">
  <div id="modal">
    <div class="mhd"><h3 id="modal-title"></h3><button onclick="closeModal()" style="background:none;border:none;color:var(--text3);cursor:pointer;font-size:15px;padding:2px 5px;border-radius:var(--rad)">✕</button></div>
    <div class="mbd" id="modal-body"></div>
    <div class="mft" id="modal-foot"></div>
  </div>
</div>

<div id="toast"></div>

<script>
// ── Constants ────────────────────────────────────────────────────────────────
const ROLES = {
  dc:             { label:'Domain Controller',  icon:'🛡', color:'#f59e0b', bg:'rgba(245,158,11,.1)',  order:0, dcpu:2, dram:4096, ddisk:75 },
  fileserver:     { label:'File Server',        icon:'📁', color:'#5b9cf6', bg:'rgba(91,156,246,.1)',  order:1, dcpu:2, dram:4096, ddisk:75 },
  backupserver:   { label:'Backup Server',      icon:'💾', color:'#a78bfa', bg:'rgba(167,139,250,.1)',order:2, dcpu:2, dram:4096, ddisk:75 },
  rds_broker:     { label:'RDS Broker',         icon:'🔀', color:'#22d3ee', bg:'rgba(34,211,238,.1)', order:3, dcpu:2, dram:4096, ddisk:75 },
  rds_sessionhost:{ label:'RDS Session Host',   icon:'🖥', color:'#3ecf5d', bg:'rgba(62,207,93,.1)',  order:4, dcpu:4, dram:8192, ddisk:75 },
  printserver:    { label:'Print Server',       icon:'🖨', color:'#f97316', bg:'rgba(249,115,22,.1)', order:5, dcpu:2, dram:2048, ddisk:75 },
  mgmt:           { label:'Management',         icon:'⚙',  color:'#94a3b8', bg:'rgba(148,163,184,.1)',order:6, dcpu:2, dram:4096, ddisk:75 },
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

// ── State ────────────────────────────────────────────────────────────────────
let S = {
  hosts:[], vms:[], selVm:null, selHost:null,
  flt:'all', view:'overview', deploying:false,
  settings:{ net:'192.168.1', gw:'192.168.1.1', pfx:24, dns1:'8.8.8.8', dns2:'8.8.4.4', cpus:2, ram:4096, disk:75, pass:'ChangeMe123!', tz:'W. Europe Standard Time', locale:'de-CH' }
};

let _uid = 1;
const uid  = () => 'v' + _uid++;
const $    = id => document.getElementById(id);
const hb   = id => S.hosts.find(h => h.id === id);
const vb   = id => S.vms.find(v => v.id === id);
const q    = () => ($('sb-input')||{}).value?.toLowerCase() || '';

function persist() {
  try { localStorage.setItem('wd6', JSON.stringify({ hosts:S.hosts, vms:S.vms, settings:S.settings })); } catch(_){}
}
function restore() {
  try {
    const d = JSON.parse(localStorage.getItem('wd6')||'{}');
    if (d.hosts) S.hosts = d.hosts;
    if (d.vms)   S.vms   = d.vms;
    if (d.settings) Object.assign(S.settings, d.settings);
  } catch(_){}
}

function toast(msg, isErr=true) {
  const t = $('toast');
  t.textContent = msg;
  t.style.background = isErr ? 'var(--red-d)' : 'var(--green-d)';
  t.style.borderColor = isErr ? 'var(--red)' : 'var(--green)';
  t.className = 'show';
  clearTimeout(t._to);
  t._to = setTimeout(() => t.className = '', 4000);
}

// ── Views ────────────────────────────────────────────────────────────────────
function setView(v, btn) {
  S.view = v;
  document.querySelectorAll('.view').forEach(e => e.classList.remove('active'));
  $('view-'+v).classList.add('active');
  document.querySelectorAll('.tnb').forEach(b => b.classList.remove('act'));
  if (!btn) document.querySelectorAll('.tnb').forEach(b => { if (b.getAttribute('onclick')?.includes("'"+v+"'")) b.classList.add('act'); });
  else btn.classList.add('act');
  if (v === 'deploy') renderDeploy();
}
function setFlt(f, btn) {
  S.flt = f;
  document.querySelectorAll('.flt').forEach(b => b.classList.remove('act'));
  btn.classList.add('act');
  renderGrid();
}

function syncSettingsForm() {
  const s = S.settings;
  $('s-net').value    = s.net    || '192.168.1';
  $('s-gw').value     = s.gw     || '192.168.1.1';
  $('s-pfx').value    = s.pfx    || 24;
  $('s-dns1').value   = s.dns1   || '8.8.8.8';
  $('s-dns2').value   = s.dns2   || '8.8.4.4';
  $('s-cpus').value   = s.cpus   || 2;
  $('s-ram').value    = s.ram    || 4096;
  $('s-disk').value   = s.disk   || 75;
  $('s-pass').value   = s.pass   || 'ChangeMe123!';
  $('s-tz').value     = s.tz     || 'W. Europe Standard Time';
  $('s-locale').value = s.locale || 'de-CH';
}

// ── Tree ─────────────────────────────────────────────────────────────────────
function renderTree(qv = '') {
  const t = $('tree'); t.innerHTML = '';
  if (!S.hosts.length) {
    t.innerHTML = '<div class="tr-empty" style="padding:14px 10px">Add a Proxmox host to begin</div>';
    return;
  }
  S.hosts.forEach(h => {
    const vms = S.vms.filter(v => v.hostId === h.id && (!qv ||
      v.hostname.toLowerCase().includes(qv) ||
      (ROLES[v.role]?.label||'').toLowerCase().includes(qv)));
    const run = vms.filter(v => v.status === 'running').length;
    const open = h._open !== false;
    const el = document.createElement('div'); el.className = 'tr-host';
    el.innerHTML = `
      <div class="tr-host-row${S.selHost===h.id?' sel':''}" onclick="clickHost('${h.id}')">
        <svg class="tr-chv${open?' open':''}" id="chv-${h.id}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="m9 18 6-6-6-6"/></svg>
        <div class="tr-host-ic"><svg width="9" height="9" viewBox="0 0 24 24" fill="#e8a020"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg></div>
        <span class="tr-host-name">${h.name}</span>
        <span class="tr-cnt" style="background:${run?'rgba(62,207,93,.12)':'rgba(61,84,112,.2)'};color:${run?'var(--green)':'var(--text3)'}">${run}/${vms.length}</span>
      </div>
      <div class="tr-kids" id="kids-${h.id}" style="display:${open?'block':'none'}">
        ${vms.length ? '' : '<div class="tr-empty">No VMs</div>'}
        ${vms.map(v => {
          const r = ROLES[v.role]||{}; const s = ST[v.status]||ST.pending;
          return `<div class="tr-vm${S.selVm===v.id?' sel':''}" onclick="clickVm('${v.id}')">
            <div class="tr-dot ${s.dot}"></div>
            <span class="tr-vm-ic">${r.icon||'□'}</span>
            <span class="tr-vm-name">${v.hostname}</span>
            <span class="tr-vm-ip">${v.ip}</span>
          </div>`;
        }).join('')}
      </div>`;
    t.appendChild(el);
  });
}

function clickHost(id) {
  const h = S.hosts.find(x => x.id === id); if (!h) return;
  h._open = !h._open;
  $('kids-'+id).style.display = h._open ? 'block' : 'none';
  const chv = $('chv-'+id); if (chv) chv.classList.toggle('open', h._open);
  S.selHost = id; S.selVm = null;
  showHostDetail(id); renderTree(q());
}
function clickVm(id) { S.selVm = id; S.selHost = null; renderTree(q()); renderGrid(); showVmDetail(id); }
function closeDetail() { S.selVm = null; S.selHost = null; $('dp').classList.remove('open'); renderTree(q()); renderGrid(); }

// ── Overview ─────────────────────────────────────────────────────────────────
function renderOverview() {
  const tot = S.vms.length,
        run = S.vms.filter(v=>v.status==='running').length,
        dep = S.vms.filter(v=>['cloning','configuring'].includes(v.status)).length,
        stp = S.vms.filter(v=>v.status==='stopped').length;
  $('ov-sub').textContent = `${S.hosts.length} host${S.hosts.length!==1?'s':''} · ${tot} VM${tot!==1?'s':''}`;
  $('stats').innerHTML = `
    <div class="stat-card"><div class="stat-v">${tot}</div><div class="stat-l">Total VMs</div></div>
    <div class="stat-card"><div class="stat-v" style="color:var(--green)">${run}</div><div class="stat-l">Running</div></div>
    <div class="stat-card"><div class="stat-v" style="color:var(--amber)">${dep}</div><div class="stat-l">Deploying</div></div>
    <div class="stat-card"><div class="stat-v" style="color:var(--red)">${stp}</div><div class="stat-l">Stopped</div></div>`;
  const n = S.hosts.length;
  $('cdot').className = 'cdot ' + (n ? 'on' : 'off');
  $('clab').textContent = n === 0 ? 'No hosts' : n === 1 ? S.hosts[0].name : `${n} hosts`;
  renderGrid();
}

function renderGrid() {
  const g = $('vmg');
  const vms = S.vms.filter(v => S.flt === 'all' || v.status === S.flt);
  if (!vms.length) {
    g.innerHTML = `<div class="empty" style="grid-column:1/-1">
      <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" opacity=".2"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
      <p>${S.vms.length ? 'No VMs match filter' : 'No VMs — click + Add VM'}</p>
    </div>`;
    return;
  }
  g.innerHTML = vms.map(v => {
    const r = ROLES[v.role]||{}; const s = ST[v.status]||ST.pending;
    const bc = v.status==='running'?'var(--green)':v.status==='stopped'?'var(--red)':v.status==='cloning'?'var(--amber)':'var(--blue)';
    return `<div class="vm-card ${ST_CLS[v.status]||'st-pend'}${S.selVm===v.id?' sel':''}" onclick="clickVm('${v.id}')">
      <div class="vc-top">
        <div class="vc-icon" style="background:${r.bg}">${r.icon||'□'}</div>
        <div style="flex:1;min-width:0"><div class="vc-name">${v.hostname}</div><div class="vc-ip">${v.ip}</div></div>
        <span class="vc-tag" style="background:${s.c}18;color:${s.c}">${s.l}</span>
      </div>
      <div class="vc-bar"><div class="vc-bar-fill" style="width:${v.prog||0}%;background:${bc}"></div></div>
      <div class="vc-meta">
        <span class="vc-m">${v.cpus} vCPU</span>
        <span class="vc-m">·</span>
        <span class="vc-m">${v.ram/1024}GB</span>
        <span class="vc-m">·</span>
        <span class="vc-m">${v.disk}GB</span>
        <span class="vc-m" style="margin-left:auto">${hb(v.hostId)?.name||'?'}</span>
      </div>
    </div>`;
  }).join('');
}

// ── Detail panels ─────────────────────────────────────────────────────────────
function showVmDetail(id) {
  const v = vb(id); if (!v) return;
  const r = ROLES[v.role]||{}; const s = ST[v.status]||ST.pending; const h = hb(v.hostId);
  const dep = ['cloning','configuring'].includes(v.status);
  $('dp').classList.add('open');
  $('dp-body').innerHTML = `
    <div class="dp-head">
      <div class="dp-hic" style="background:${r.bg}">${r.icon||'□'}</div>
      <div style="flex:1;overflow:hidden"><div class="dp-htitle">${v.hostname}</div><div class="dp-hsub">${r.label}</div></div>
      <button class="dp-x" onclick="closeDetail()">✕</button>
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">Status</div>
      <div style="display:flex;align-items:center;gap:6px;${dep?'margin-bottom:7px':''}">
        <div class="tr-dot ${s.dot}" style="width:6px;height:6px"></div>
        <span style="font-weight:600;color:${s.c};font-size:12px">${s.l}</span>
      </div>
      ${dep ? `<div style="font-size:10px;color:var(--text3);margin-bottom:3px">${Math.round(v.prog||0)}%</div><div class="vc-bar"><div class="vc-bar-fill" style="width:${v.prog||0}%;background:${s.c}"></div></div>` : ''}
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">Network</div>
      <div class="dp-row"><span class="dp-k">IP Address</span><span class="dp-v">${v.ip}</span></div>
      <div class="dp-row"><span class="dp-k">Gateway</span><span class="dp-v">${S.settings.gw}</span></div>
      <div class="dp-row"><span class="dp-k">DNS</span><span class="dp-v">${S.settings.dns1}</span></div>
      <div class="dp-row"><span class="dp-k">RDP</span><span class="dp-v" style="color:var(--green)">Enabled</span></div>
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">Resources</div>
      <div class="dp-row"><span class="dp-k">CPUs</span><span class="dp-v">${v.cpus} vCPU</span></div>
      <div class="dp-row"><span class="dp-k">RAM</span><span class="dp-v">${v.ram/1024} GB</span></div>
      <div class="dp-row"><span class="dp-k">Disk</span><span class="dp-v">${v.disk} GB</span></div>
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">Config</div>
      <div class="dp-row"><span class="dp-k">Host</span><span class="dp-v">${h?.name||'—'}</span></div>
      <div class="dp-row"><span class="dp-k">Role</span><span class="dp-v">${v.role}</span></div>
    </div>
    <div class="dp-actions">
      <button class="btn btn-g btn-fw" onclick="openModal('edit-vm','${v.id}')">✏ Edit</button>
      <div class="sep"></div>
      <button class="btn btn-d btn-fw" onclick="delVm('${v.id}')">🗑 Remove</button>
    </div>`;
}

function showHostDetail(id) {
  const h = hb(id); if (!h) return;
  const vms = S.vms.filter(v => v.hostId === id);
  const run = vms.filter(v => v.status === 'running').length;
  $('dp').classList.add('open');
  $('dp-body').innerHTML = `
    <div class="dp-head">
      <div class="dp-hic" style="background:var(--amber-d);border:1px solid var(--amber-b)">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--amber)" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
      </div>
      <div style="flex:1"><div class="dp-htitle">${h.name}</div><div class="dp-hsub">${h.host} · ${h.node}</div></div>
      <button class="dp-x" onclick="closeDetail()">✕</button>
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">Connection</div>
      <div class="dp-row"><span class="dp-k">Host</span><span class="dp-v">${h.host}</span></div>
      <div class="dp-row"><span class="dp-k">Node</span><span class="dp-v">${h.node}</span></div>
      <div class="dp-row"><span class="dp-k">Template Name</span><span class="dp-v">${h.templateName}</span></div>
      <div class="dp-row"><span class="dp-k">Storage</span><span class="dp-v">${h.storage}</span></div>
      <div class="dp-row"><span class="dp-k">Bridge</span><span class="dp-v">${h.bridge}</span></div>
    </div>
    <div class="dp-sec">
      <div class="dp-sec-title">VMs on this host</div>
      <div class="dp-row"><span class="dp-k">Total</span><span class="dp-v">${vms.length}</span></div>
      <div class="dp-row"><span class="dp-k">Running</span><span class="dp-v" style="color:var(--green)">${run}</span></div>
    </div>
    ${vms.length ? `<div class="dp-sec"><div class="dp-sec-title">VM List</div>${vms.map(v=>{const r=ROLES[v.role]||{};const s=ST[v.status]||ST.pending;return`<div class="dp-row" style="cursor:pointer" onclick="clickVm('${v.id}')"><span class="dp-k">${r.icon||''} ${v.hostname}</span><span class="dp-v" style="color:${s.c}">${s.l}</span></div>`;}).join('')}</div>` : ''}
    <div class="dp-actions">
      <a href="https://${h.host}:8006" target="_blank" class="btn btn-g btn-fw">🔗 Open Proxmox UI</a>
      <button class="btn btn-g btn-fw" onclick="openModal('edit-host','${h.id}')">✏ Edit Host</button>
      <div class="sep"></div>
      <button class="btn btn-d btn-fw" onclick="delHost('${h.id}')">🗑 Remove Host</button>
    </div>`;
}

// ── Deploy ────────────────────────────────────────────────────────────────────
function renderDeploy() {
  const ordered = ROLE_ORDER.flatMap(role => S.vms.filter(v => v.role === role));
  $('q-ct').textContent = ordered.length + ' VMs';
  $('dep-steps').innerHTML = ordered.length ? ordered.map((v, i) => {
    const r = ROLES[v.role]||{}; const s = ST[v.status]||ST.pending;
    const cls = v.status==='running'?'done':['cloning','configuring'].includes(v.status)?'active':'pend';
    const tick = v.status==='running'?'✓':['cloning','configuring'].includes(v.status)?'…':(i+1);
    return `<div class="step ${cls}">
      <div class="step-dc">
        <div class="step-dot">${tick}</div>
        ${i < ordered.length-1 ? '<div class="step-line"></div>' : ''}
      </div>
      <div style="flex:1;padding-top:1px">
        <div class="step-name">${r.icon} ${v.hostname}</div>
        <div class="step-sub">${r.label} · ${v.ip}</div>
      </div>
      <span class="pill" style="background:${s.c}15;color:${s.c};align-self:flex-start;margin-top:2px">${s.l}</span>
    </div>`;
  }).join('') : '<div class="empty"><p>No VMs defined</p></div>';

  $('role-order').innerHTML = ROLE_ORDER.map((role, i) => {
    const r = ROLES[role]||{}; const n = S.vms.filter(v => v.role === role).length;
    return `<div style="display:flex;align-items:center;gap:7px;padding:5px 0;border-bottom:1px solid var(--b1)${i===ROLE_ORDER.length-1?';border:none':''}">
      <span style="font-family:var(--mono);font-size:9px;color:var(--text3);width:11px;text-align:right">${i+1}</span>
      <span style="font-size:11px">${r.icon}</span>
      <span style="font-size:11.5px;flex:1">${r.label}</span>
      ${n ? `<span class="pill" style="background:${r.bg};color:${r.color}">${n}</span>` : `<span style="font-size:10px;color:var(--text3)">—</span>`}
    </div>`;
  }).join('');
}

// ── Deploy — sendet Frontend-Konfiguration ans Backend ─────────────────────
let _pollInterval = null;

async function startDeploy() {
  if (S.deploying) return;
  if (!S.hosts.length) { toast('No Proxmox hosts configured'); return; }
  if (!S.vms.length)   { toast('No VMs defined'); return; }

  S.deploying = true;
  $('dep-btn').disabled = true;
  $('live-b').innerHTML = '<span style="font-size:10px;color:var(--amber);font-family:var(--mono);animation:blink .8s infinite">● STARTING</span>';
  $('log').textContent = '[windows-deployment] Sending deploy request…\n';

  try {
    // ── FIX: Konfiguration aus dem Frontend-State mitschicken ──────────────
    const res = await fetch('/api/deploy', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        config: {
          hosts:    S.hosts,
          vms:      S.vms,
          settings: S.settings
        }
      })
    });
    const data = await res.json();
    if (!res.ok) {
      toast(data.error || 'Deploy failed to start');
      stopDeploy();
      return;
    }
  } catch(e) {
    toast('Cannot reach backend: ' + e.message);
    stopDeploy();
    return;
  }

  $('live-b').innerHTML = '<span style="font-size:10px;color:var(--green);font-family:var(--mono);animation:blink .8s infinite">● LIVE</span>';
  $('deploy-status-bar').classList.add('visible');

  _pollInterval = setInterval(pollDeployStatus, 1500);
}

async function pollDeployStatus() {
  try {
    const res = await fetch('/api/deploy/status');
    const data = await res.json();
    const log = $('log');
    if (data.log !== undefined) {
      log.textContent = data.log;
      log.scrollTop = log.scrollHeight;
    }
    if (!data.running) {
      const failed = data.exitCode !== 0;
      if (failed) {
        log.style.color = 'var(--red)';
        log.style.borderColor = 'var(--red)';
        $('live-b').innerHTML = '<span style="font-size:10px;color:var(--red);font-family:var(--mono)">✗ FAILED (code '+data.exitCode+')</span>';
        $('dsb-text').textContent = 'Deploy failed';
        setTimeout(() => {
          log.style.color = '';
          log.style.borderColor = '';
        }, 5000);
      } else {
        $('live-b').innerHTML = '<span style="font-size:10px;color:var(--green);font-family:var(--mono)">✓ Done</span>';
        $('dsb-text').textContent = 'Deploy finished';
      }
      stopDeploy();
    } else {
      $('dsb-text').textContent = 'Deploy running…';
    }
  } catch(_) {}
}

function stopDeploy() {
  S.deploying = false;
  $('dep-btn').disabled = false;
  clearInterval(_pollInterval);
  setTimeout(() => $('deploy-status-bar').classList.remove('visible'), 3000);
}

// ── Settings ──────────────────────────────────────────────────────────────────
function saveSettings() {
  S.settings.net    = $('s-net').value;
  S.settings.gw     = $('s-gw').value;
  S.settings.pfx    = +$('s-pfx').value || 24;
  S.settings.dns1   = $('s-dns1').value;
  S.settings.dns2   = $('s-dns2').value;
  S.settings.cpus   = +$('s-cpus').value || 2;
  S.settings.ram    = +$('s-ram').value || 4096;
  S.settings.disk   = +$('s-disk').value || 75;
  S.settings.pass   = $('s-pass').value;
  S.settings.tz     = $('s-tz').value;
  S.settings.locale = $('s-locale').value;
  persist();
  const btn = $('save-btn');
  btn.textContent = '✓ Saved'; btn.style.background = 'var(--green)'; btn.style.color = '#000';
  setTimeout(() => { btn.textContent = 'Save'; btn.style.background = ''; btn.style.color = ''; }, 1600);
}

// ── Modals ────────────────────────────────────────────────────────────────────
function openModal(type, id) {
  $('modal-bg').classList.add('open');
  const s = S.settings;

  if (type === 'host') {
    $('modal-title').textContent = 'Add Proxmox Host';
    $('modal-body').innerHTML = `
      <div class="ff"><label>Display Name</label><input id="m-name" autocomplete="off" placeholder="pve-main"></div>
      <div class="g2">
        <div class="ff"><label>Host IP / FQDN</label><input id="m-host" autocomplete="off" placeholder="192.168.1.2"></div>
        <div class="ff"><label>Node Name</label><input id="m-node" autocomplete="off" value="pve"></div>
      </div>
      <div class="ff"><label>API Token ID</label><input id="m-tokid" autocomplete="off" placeholder="root@pam!windeployment"></div>
      <div class="ff"><label>API Token Secret</label><input type="password" id="m-toksec" autocomplete="new-password" placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"></div>
      <div class="g2">
        <div class="ff"><label>Template VM Name</label><input id="m-tmpl" autocomplete="off" placeholder="win2025-template"></div>
        <div class="ff"><label>Storage Pool</label><input id="m-stor" autocomplete="off" value="local-lvm"></div>
      </div>
      <div class="ff"><label>Network Bridge</label><input id="m-bridge" autocomplete="off" value="vmbr0"></div>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveHost()">⚡ Connect & Save</button>`;
  }

  if (type === 'edit-host') {
    const h = hb(id); if (!h) return;
    $('modal-title').textContent = 'Edit Host — ' + h.name;
    $('modal-body').innerHTML = `
      <div class="ff"><label>Display Name</label><input id="m-name" autocomplete="off" value="${h.name}"></div>
      <div class="g2">
        <div class="ff"><label>Host IP / FQDN</label><input id="m-host" autocomplete="off" value="${h.host}"></div>
        <div class="ff"><label>Node Name</label><input id="m-node" autocomplete="off" value="${h.node}"></div>
      </div>
      <div class="ff"><label>API Token ID</label><input id="m-tokid" autocomplete="off" value="${h.tokenId}"></div>
      <div class="ff"><label>API Token Secret</label><input type="password" id="m-toksec" autocomplete="new-password" placeholder="Leave blank to keep current"></div>
      <div class="g2">
        <div class="ff"><label>Template VM Name</label><input id="m-tmpl" autocomplete="off" value="${h.templateName}"></div>
        <div class="ff"><label>Storage Pool</label><input id="m-stor" autocomplete="off" value="${h.storage}"></div>
      </div>
      <div class="ff"><label>Network Bridge</label><input id="m-bridge" autocomplete="off" value="${h.bridge}"></div>`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveEditHost('${id}')">Save</button>`;
  }

  if (type === 'vm') {
    const defRole = ROLES['dc'];
    $('modal-title').textContent = 'Add VM';
    $('modal-body').innerHTML = `
      <div class="ff"><label>Role</label>
        <select id="m-role" onchange="applyRoleDef(this.value)">
          ${Object.entries(ROLES).map(([k,v])=>`<option value="${k}">${v.icon}  ${v.label}</option>`).join('')}
        </select>
      </div>
      <div class="g2">
        <div class="ff"><label>Hostname</label><input id="m-hn" autocomplete="off" placeholder="dc01"></div>
        <div class="ff"><label>IP Address</label><input id="m-ip" autocomplete="off" placeholder="${s.net}.10"></div>
      </div>
      <div class="g3">
        <div class="ff"><label>CPUs</label><input type="number" id="m-cpus" autocomplete="off" value="${defRole.dcpu}"></div>
        <div class="ff"><label>RAM (MB)</label><input type="number" id="m-ram" autocomplete="off" value="${defRole.dram}" step="1024"></div>
        <div class="ff"><label>Disk (GB)</label><input type="number" id="m-disk" autocomplete="off" value="${s.disk}"></div>
      </div>
      ${S.hosts.length > 1
        ? `<div class="ff"><label>Proxmox Host</label><select id="m-hid">${S.hosts.map(h=>`<option value="${h.id}">${h.name} (${h.host})</option>`).join('')}</select></div>`
        : `<input type="hidden" id="m-hid" value="${S.hosts[0]?.id||''}">`}`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveVm()">+ Add VM</button>`;
  }

  if (type === 'edit-vm') {
    const v = vb(id); if (!v) return;
    $('modal-title').textContent = 'Edit — ' + v.hostname;
    $('modal-body').innerHTML = `
      <div class="ff"><label>Role</label>
        <select id="e-role">
          ${Object.entries(ROLES).map(([k,r])=>`<option value="${k}"${k===v.role?' selected':''}>${r.icon}  ${r.label}</option>`).join('')}
        </select>
      </div>
      <div class="g2">
        <div class="ff"><label>Hostname</label><input id="e-hn" autocomplete="off" value="${v.hostname}"></div>
        <div class="ff"><label>IP Address</label><input id="e-ip" autocomplete="off" value="${v.ip}"></div>
      </div>
      <div class="g3">
        <div class="ff"><label>CPUs</label><input type="number" id="e-cpus" autocomplete="off" value="${v.cpus}"></div>
        <div class="ff"><label>RAM (MB)</label><input type="number" id="e-ram" autocomplete="off" value="${v.ram}" step="1024"></div>
        <div class="ff"><label>Disk (GB)</label><input type="number" id="e-disk" autocomplete="off" value="${v.disk}"></div>
      </div>
      ${S.hosts.length > 1
        ? `<div class="ff"><label>Host</label><select id="e-hid">${S.hosts.map(h=>`<option value="${h.id}"${h.id===v.hostId?' selected':''}>${h.name}</option>`).join('')}</select></div>`
        : ''}`;
    $('modal-foot').innerHTML = `<button class="btn btn-g" onclick="closeModal()">Cancel</button><button class="btn btn-a" onclick="saveEditVm('${id}')">Save</button>`;
  }
}

function applyRoleDef(role) {
  const r = ROLES[role]||{};
  if (r.dcpu) $('m-cpus').value = r.dcpu;
  if (r.dram) $('m-ram').value  = r.dram;
}

function saveHost() {
  const n = ($('m-name').value||'').trim(), h = ($('m-host').value||'').trim();
  if (!n||!h) { toast('Name and host IP required'); return; }
  const newHost = {
    id: uid(), name:n, host:h,
    node:        $('m-node').value   || 'pve',
    tokenId:     $('m-tokid').value,
    tokenSecret: $('m-toksec').value,
    templateName: $('m-tmpl').value || 'win2025-template',
    storage:     $('m-stor').value   || 'local-lvm',
    bridge:      $('m-bridge').value || 'vmbr0',
    _open: true
  };
  S.hosts.push(newHost);
  persist(); closeModal(); renderAll();
  toast('Host added', false);
}

function saveEditHost(id) {
  const h = hb(id); if (!h) return;
  h.name        = $('m-name').value  || h.name;
  h.host        = $('m-host').value  || h.host;
  h.node        = $('m-node').value  || h.node;
  h.tokenId     = $('m-tokid').value || h.tokenId;
  const newSecret = $('m-toksec').value;
  if (newSecret) h.tokenSecret = newSecret;
  h.templateName = $('m-tmpl').value || h.templateName;
  h.storage     = $('m-stor').value  || h.storage;
  h.bridge      = $('m-bridge').value || h.bridge;
  persist(); closeModal(); renderAll();
  if (S.selHost === id) showHostDetail(id);
  toast('Host updated', false);
}

function saveVm() {
  const hn = ($('m-hn').value||'').trim(), ip = ($('m-ip').value||'').trim();
  if (!hn||!ip) { toast('Hostname and IP required'); return; }
  if (!S.hosts.length) { toast('Add a Proxmox host first'); return; }
  S.vms.push({
    id: uid(),
    hostId: $('m-hid').value || S.hosts[0].id,
    role:   $('m-role').value,
    hostname: hn,
    name: hn,
    ip,
    cpus:  +$('m-cpus').value || S.settings.cpus,
    ram:   +$('m-ram').value  || S.settings.ram,
    disk:  +$('m-disk').value || S.settings.disk,
    status: 'pending', prog: 0
  });
  persist(); closeModal(); renderAll();
}

function saveEditVm(id) {
  const v = vb(id); if (!v) return;
  v.role     = $('e-role').value;
  v.hostname = $('e-hn').value || v.hostname;
  v.name     = v.hostname;
  v.ip       = $('e-ip').value  || v.ip;
  v.cpus     = +$('e-cpus').value || v.cpus;
  v.ram      = +$('e-ram').value  || v.ram;
  v.disk     = +$('e-disk').value || v.disk;
  if ($('e-hid')) v.hostId = $('e-hid').value;
  persist(); closeModal(); renderAll(); showVmDetail(id);
}

function delVm(id) {
  if (!confirm('Remove VM? This does not delete it from Proxmox.')) return;
  S.vms = S.vms.filter(v => v.id !== id); persist(); closeDetail(); renderAll();
}
function delHost(id) {
  if (!confirm('Remove host and all its VM definitions?')) return;
  S.hosts = S.hosts.filter(h => h.id !== id);
  S.vms   = S.vms.filter(v => v.hostId !== id);
  persist(); closeDetail(); renderAll();
}
function closeModal() { $('modal-bg').classList.remove('open'); }
function renderAll() {
  renderTree(q()); renderOverview();
  if (S.view === 'deploy') renderDeploy();
  if (S.selVm) showVmDetail(S.selVm);
  else if (S.selHost) showHostDetail(S.selHost);
}

document.querySelectorAll('.tnb').forEach(b => {
  b.addEventListener('click', () => {
    if (b.getAttribute('onclick')?.includes("'settings'")) syncSettingsForm();
  });
});

restore();
syncSettingsForm();
renderAll();
</script>
</body>
</html>
HTML_EOF

  # ---------------------------------------------------------------------------
  # backend/server.js
  # ---------------------------------------------------------------------------
  cat > "${DIR}/backend/server.js" << 'JS_EOF'
const express  = require('express');
const cors     = require('cors');
const fs       = require('fs');
const path     = require('path');
const https    = require('https');
const { exec } = require('child_process');

const app = express();
app.use(cors());
app.use(express.json());

const DATA = path.join(__dirname, 'data', 'config.json');
const INV  = path.join(__dirname, '../ansible/inventory/hosts.ini');
const ADIR = path.join(__dirname, '../ansible');

fs.mkdirSync(path.dirname(DATA), { recursive: true });
fs.mkdirSync(path.dirname(INV),  { recursive: true });

const load = () => { try { return JSON.parse(fs.readFileSync(DATA, 'utf8')); } catch { return { hosts:[], vms:[], settings:{} }; } };
const save = c  => fs.writeFileSync(DATA, JSON.stringify(c, null, 2));

// Proxmox API connectivity check
function pveCheck(host, tokenId, tokenSecret, node) {
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: host, port: 8006,
      path: `/api2/json/nodes/${node}/status`,
      method: 'GET',
      headers: { 'Authorization': `PVEAPIToken=${tokenId}=${tokenSecret}` },
      rejectUnauthorized: false,
    }, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => { try { resolve(JSON.parse(d)); } catch { resolve({}); } });
    });
    req.on('error', reject);
    req.end();
  });
}

// ── Hosts ────────────────────────────────────────────────────────────────────
app.get('/api/hosts', (req, res) =>
  res.json(load().hosts.map(h => ({ ...h, tokenSecret: '***' })))
);

app.post('/api/hosts', async (req, res) => {
  const { name, host, node, tokenId, tokenSecret, templateName, storage, bridge } = req.body;
  if (!name || !host || !tokenId || !tokenSecret) return res.status(400).json({ error: 'name, host, tokenId, tokenSecret required' });
  try {
    const t = await pveCheck(host, tokenId, tokenSecret, node || 'pve');
    if (!t.data) throw new Error('Node returned no data — check token permissions');
  } catch (e) {
    return res.status(400).json({ error: `Cannot connect to Proxmox: ${e.message}` });
  }
  const c = load();
  c.hosts = c.hosts.filter(h => h.host !== host);
  c.hosts.push({ id: Date.now().toString(), name, host, node: node||'pve', tokenId, tokenSecret, templateName: templateName||'win2025-template', storage: storage||'local-lvm', bridge: bridge||'vmbr0' });
  save(c); res.json({ success: true });
});

app.put('/api/hosts/:id', (req, res) => {
  const c = load(); const i = c.hosts.findIndex(h => h.id === req.params.id);
  if (i === -1) return res.status(404).json({ error: 'Host not found' });
  const update = { ...req.body };
  if (!update.tokenSecret) delete update.tokenSecret;
  c.hosts[i] = { ...c.hosts[i], ...update, id: req.params.id };
  save(c); res.json({ success: true });
});

app.delete('/api/hosts/:id', (req, res) => {
  const c = load(); c.hosts = c.hosts.filter(h => h.id !== req.params.id); save(c); res.json({ success: true });
});

// ── VMs ───────────────────────────────────────────────────────────────────────
app.get('/api/vms', (req, res) => res.json(load().vms || []));

app.post('/api/vms', (req, res) => {
  const c = load();
  const vm = { id: Date.now().toString(), ...req.body, name: req.body.hostname, status: 'pending', prog: 0 };
  c.vms = [...(c.vms||[]), vm]; save(c); res.json({ success: true, vm });
});

app.put('/api/vms/:id', (req, res) => {
  const c = load(); const i = c.vms.findIndex(v => v.id === req.params.id);
  if (i === -1) return res.status(404).json({ error: 'Not found' });
  c.vms[i] = { ...c.vms[i], ...req.body, id: req.params.id, name: req.body.hostname || c.vms[i].hostname };
  save(c); res.json({ success: true });
});

app.delete('/api/vms/:id', (req, res) => {
  const c = load(); c.vms = c.vms.filter(v => v.id !== req.params.id); save(c); res.json({ success: true });
});

// ── Settings ──────────────────────────────────────────────────────────────────
app.get('/api/settings', (req, res) => res.json(load().settings || {}));
app.put('/api/settings', (req, res) => { const c = load(); c.settings = req.body; save(c); res.json({ success: true }); });

// ── Deploy ────────────────────────────────────────────────────────────────────
let running = false;
let deployLog = '';
let lastExitCode = 0;

app.post('/api/deploy', (req, res) => {
  if (running) return res.status(409).json({ error: 'Deploy already running' });

  // ── FIX: Konfiguration aus dem Request-Body verwenden (vom Frontend),
  //         Fallback auf config.json falls nichts mitgeschickt wurde.
  const c = (req.body && req.body.config) ? req.body.config : load();

  if (!c.hosts?.length) return res.status(400).json({ error: 'No Proxmox hosts configured' });
  if (!c.vms?.length)   return res.status(400).json({ error: 'No VMs configured' });

  const s = c.settings || {};
  const h = c.hosts[0]; // primary host

  const ROLE_ORDER = ['dc','fileserver','backupserver','rds_broker','rds_sessionhost','printserver','mgmt'];

  // ── Generate Ansible inventory ─────────────────────────────────────────────
  // Only include roles that actually have VMs — undefined groups break ini parsing
  const activeRoles = ROLE_ORDER.filter(role => c.vms.some(v => v.role === role));

  let ini = `# Generated by windows-deployment ${new Date().toISOString()}\n`;
  ini += `[windows:children]\n${activeRoles.join('\n')}\n\n`;

  activeRoles.forEach(role => {
    const members = c.vms.filter(v => v.role === role);
    ini += `[${role}]\n`;
    members.forEach(v => ini += `${v.hostname} ansible_host=${v.ip}\n`);
    ini += '\n';
  });

  ini += `[windows:vars]
ansible_user=Administrator
ansible_password=${s.pass||'ChangeMe123!'}
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_port=5985
ansible_winrm_server_cert_validation=ignore
network_gateway=${s.gw||'192.168.1.1'}
network_prefix_length=${s.pfx||24}
dns_primary=${s.dns1||'8.8.8.8'}
dns_secondary=${s.dns2||'8.8.4.4'}
win_timezone=${s.tz||'W. Europe Standard Time'}
win_locale=${s.locale||'de-CH'}
`;
  fs.writeFileSync(INV, ini);

  // ── Build servers JSON for proxmox_provision role ─────────────────────────
  const serversJson = JSON.stringify(c.vms.map(v => ({
    hostname: v.hostname,
    ip:       v.ip,
    cpus:     v.cpus || 2,
    ram:      v.ram  || 4096,
    disk:     v.disk || 75,
    role:     v.role,
  })));

  const extraVars = {
    proxmox_host:          h.host,
    proxmox_node:          h.node,
    proxmox_template_name: h.templateName || h.templateVmId || 'win2025-template',
    proxmox_storage:       h.storage,
    proxmox_bridge:        h.bridge,
    proxmox_token_id:      h.tokenId,
    proxmox_token_secret:  h.tokenSecret,
    win_admin_pass:        s.pass || 'ChangeMe123!',
    network_gateway:       s.gw   || '192.168.1.1',
    network_prefix_length: s.pfx  || 24,
    dns_primary:           s.dns1 || '8.8.8.8',
    dns_secondary:         s.dns2 || '8.8.4.4',
    win_timezone:          s.tz   || 'W. Europe Standard Time',
    win_locale:            s.locale || 'de-CH',
  };

  // Extra-vars als JSON-Datei schreiben (vermeidet Shell-Quoting-Probleme)
  const evFile = path.join(ADIR, 'inventory', '_extra_vars.json');
  fs.writeFileSync(evFile, JSON.stringify({ ...extraVars, servers: JSON.parse(serversJson) }));

  deployLog = '';
  running = true;
  res.json({ success: true });

  const cmd = `cd "${ADIR}" && $(python3 -c "import shutil; print(shutil.which('ansible-playbook') or '/usr/local/bin/ansible-playbook')") site.yml -i inventory/hosts.ini -e "@inventory/_extra_vars.json" 2>&1`;
  const proc = exec(cmd);

  proc.stdout?.on('data', d => { deployLog += d; });
  proc.stderr?.on('data', d => { deployLog += d; });
  proc.on('close', code => {
    running = false;
    lastExitCode = code;
    deployLog += `\n[windows-deployment] Process exited with code ${code}\n`;
    try { fs.unlinkSync(evFile); } catch(_) {}
  });
});

app.get('/api/deploy/status', (req, res) => {
  res.json({ running, log: deployLog, exitCode: lastExitCode });
});

// ── Static frontend ────────────────────────────────────────────────────────
app.use(express.static(path.join(__dirname, '../frontend')));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, '../frontend/index.html')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`windows-deployment → http://0.0.0.0:${PORT}`));
JS_EOF

  echo '{"name":"windows-deployment","version":"1.0.0","main":"server.js","scripts":{"start":"node server.js"},"dependencies":{"express":"^4.18.2","cors":"^2.8.5"}}' > "${DIR}/backend/package.json"

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
network_gateway: "192.168.1.1"
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

- name: Parse API user and token name from full token ID
  ansible.builtin.set_fact:
    pve_api_user:   "{{ proxmox_token_id.split('!')[0] }}"
    pve_token_name: "{{ proxmox_token_id.split('!')[1] if '!' in proxmox_token_id else proxmox_token_id }}"

# community.proxmox.proxmox_kvm clone requires the template VM *name* (not VMID).
# We now store templateName in the host config, so this works via API token only.
- name: Clone template to VM
  community.proxmox.proxmox_kvm:
    api_host:         "{{ proxmox_host }}"
    api_user:         "{{ pve_api_user }}"
    api_token_id:     "{{ pve_token_name }}"
    api_token_secret: "{{ proxmox_token_secret }}"
    node:             "{{ proxmox_node }}"
    clone:            "{{ proxmox_template_name }}"
    name:             "{{ item.hostname }}"
    full:             true
    storage:          "{{ proxmox_storage }}"
    timeout:          300
    state:            present
  loop: "{{ servers }}"
  loop_control:
    label: "{{ item.hostname }}"

- name: Configure CPU and RAM
  community.proxmox.proxmox_kvm:
    api_host:         "{{ proxmox_host }}"
    api_user:         "{{ pve_api_user }}"
    api_token_id:     "{{ pve_token_name }}"
    api_token_secret: "{{ proxmox_token_secret }}"
    node:             "{{ proxmox_node }}"
    name:             "{{ item.hostname }}"
    cores:            "{{ item.cpus | int }}"
    memory:           "{{ item.ram | int }}"
    update:           true
  loop: "{{ servers }}"
  loop_control:
    label: "{{ item.hostname }}"

- name: Apply Cloud-Init config via API
  community.proxmox.proxmox_kvm:
    api_host:         "{{ proxmox_host }}"
    api_user:         "{{ pve_api_user }}"
    api_token_id:     "{{ pve_token_name }}"
    api_token_secret: "{{ proxmox_token_secret }}"
    node:             "{{ proxmox_node }}"
    name:             "{{ item.hostname }}"
    ipconfig:
      ipconfig0: "ip={{ item.ip }}/{{ network_prefix_length }},gw={{ network_gateway }}"
    nameservers:      "{{ dns_primary }}"
    cipassword:       "{{ win_admin_pass }}"
    update:           true
  loop: "{{ servers }}"
  loop_control:
    label: "{{ item.hostname }}"

- name: Start VMs
  community.proxmox.proxmox_kvm:
    api_host:         "{{ proxmox_host }}"
    api_user:         "{{ pve_api_user }}"
    api_token_id:     "{{ pve_token_name }}"
    api_token_secret: "{{ proxmox_token_secret }}"
    node:             "{{ proxmox_node }}"
    name:             "{{ item.hostname }}"
    state:            started
  loop: "{{ servers }}"
  loop_control:
    label: "{{ item.hostname }}"

- name: Wait for VMs to boot (90s)
  ansible.builtin.pause:
    seconds: 90
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

ROLES = [
("common/tasks/main.yml", [
"---",
"- name: Wait for WinRM",
"  ansible.builtin.wait_for:",
"    host:    '{{ ansible_host }}'",
"    port:    5985",
"    timeout: 600",
"    delay:   30",
"  delegate_to: localhost",
"",
"- name: Hostname, Timezone, DNS, RDP, Firewall",
"  ansible.builtin.raw: |",
"    $ErrorActionPreference = 'Stop'",
"    $needReboot = $false",
"    $desired = '{{ inventory_hostname_short }}'",
"    if ($env:COMPUTERNAME -ne $desired) {",
"      Rename-Computer -NewName $desired -Force",
"      $needReboot = $true",
"    }",
"    Set-TimeZone -Id '{{ win_timezone }}'",
"    $dns = @('{{ dns_primary }}', '{{ dns_secondary }}')",
"    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {",
"      Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses $dns",
"    }",
r"    Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' fDenyTSConnections 0",
'    netsh advfirewall firewall set rule group="remote desktop" new enable=Yes',
"    if ($needReboot) { Restart-Computer -Force }",
"",
"- name: Wait for reboot",
"  ansible.builtin.wait_for:",
"    host:    '{{ ansible_host }}'",
"    port:    5985",
"    timeout: 300",
"    delay:   30",
"  delegate_to: localhost",
]),

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
'  ansible.builtin.raw: echo "Backup server — install backup software manually"',
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
'    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes',
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
  echo -e "${BOLD}${RED}Removes:${NC} service · ${DIR} · firewall rules"
  echo -e "${YEL}Proxmox VMs are not affected.${NC}\n"
  read -rp "$(echo -e "${BOLD}${RED}Type 'yes' to confirm: ${NC}")" c
  [[ "$c" == "yes" ]] || { echo "Aborted."; exit 0; }

  systemctl stop    "${APP}" 2>/dev/null && ok "Stopped"  || true
  systemctl disable "${APP}" 2>/dev/null && ok "Disabled" || true
  [[ -f "$SVC" ]] && rm -f "$SVC" && systemctl daemon-reload && ok "Service file removed"

  BAK=""
  if [[ -f "${DIR}/backend/data/config.json" ]]; then
    BAK="/tmp/${APP}-config-$(date +%Y%m%d-%H%M%S).json"
    cp "${DIR}/backend/data/config.json" "$BAK" && ok "Config backed up → ${BAK}"
  fi
  [[ -d "$DIR" ]] && rm -rf "$DIR" && ok "Removed: ${DIR}"
  command -v ufw &>/dev/null && ufw delete allow 3000/tcp 2>/dev/null || true
  [[ -f "$LOG" ]] && rm -f "$LOG"

  echo -e "\n${BOLD}${GREEN}✓ Fully uninstalled${NC}"
  [[ -n "$BAK" ]] && echo -e "  Config backup: ${BOLD}${BAK}${NC}"
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
