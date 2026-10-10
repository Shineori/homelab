#!/usr/bin/env python3
import sys
import json
import subprocess
from datetime import datetime

WEBHOOK_URL = "https://discord.com/api/webhooks/<redacted>"

TRIGGERS = {
    "auth_log":       ("🔑 Auth Log Changed",      0xFF0000),
    "identity":       ("👤 Identity File Changed",  0xFF6600),
    "priv_esc":       ("⚠️ Sudo/Priv Esc Used",     0xFFFF00),
    "sshd_config":    ("🔒 SSH Config Changed",     0xFF0000),
    "cron_changes":   ("⏰ Crontab Modified",        0xFF6600),
    "sudoers":        ("🚨 Sudoers Modified",        0xFF0000),
    "homedir_changes":("🏠 Home Dir Modified",       0x9900FF),
}

def send_discord(title, description):
    payload = {"content": f"**{title}**\n{description}"}
    subprocess.run([
        "curl", "-s",
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload),
        WEBHOOK_URL
    ], capture_output=True)

def parse_fields(line):
    fields = {}
    for part in line.split():
        if '=' in part:
            k, v = part.split('=', 1)
            fields[k] = v.strip('"')
    return fields

def format_message(fields, raw):
    # Skip startup noise
    if fields.get('type') == 'CONFIG_CHANGE' and fields.get('op') == 'add_rule':
        return None

    # Skip kernel/system rule management noise
    if fields.get('auid') == '4294967295':
        return None

    lines = []
    if fields.get('auid', '?') != '?':  lines.append(f"👤 **User:** `{fields['auid']}`")
    if fields.get('exe'):               lines.append(f"⚙️ **Executable:** `{fields['exe']}`")
    if fields.get('name'):              lines.append(f"📄 **File:** `{fields['name']}`")
    if fields.get('op'):                lines.append(f"🔧 **Operation:** `{fields['op']}`")
    if fields.get('res'):
        icon = '✅' if fields['res'] == 'success' else '❌'
        lines.append(f"{icon} **Result:** `{fields['res']}`")

    # Fallback if nothing parsed
    if not lines:
        lines.append(f"```\n{raw[:200]}\n```")

    return '\n'.join(lines)

def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        for key, (title, color) in TRIGGERS.items():
            if f"key={key}" in line or f'key="{key}"' in line:
                fields = parse_fields(line)
                msg = format_message(fields, line)
                if msg:
                    send_discord(title, msg)
                break

if __name__ == "__main__":
    main()
