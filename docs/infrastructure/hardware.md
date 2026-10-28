# Hardware

| Machine | Role | OS | Specs | Notes |
|---|---|---|---|---|
| **ShiNAS** | Main server: storage + most Docker stacks | Vendor NAS OS (Debian-based) | 7.5 GB RAM, two drives (data + backup disk) | Stacks live in `~/docker` |
| **ShineoriServer** | RAM-hungry workloads: Ollama, Minecraft, Immich ML, Dawarich, Karakeep, Uptime Kuma, Paperless, Omada Controller (on demand) | Linux | 31 GB RAM, RTX 2060 (used by Ollama; Immich ML runs on the CPU) | Laptop repurposed as a server |
| **Windows PC** | Labs (VMware, EVE-NG, pentesting); used to host The Forest server (retired) | Windows 11 | | |

> 🔒 Hardware vendors and models are intentionally left out. Publishing them would advertise exactly which firmware vulnerabilities apply to my network.

## Future plans
- Custom NUC-based router running OPNsense (rehearsing in a VM first)
