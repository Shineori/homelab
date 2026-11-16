# Wazuh detection validation

> An authorized attack simulation against my own NAS, to test whether my SIEM actually detects common attacker behaviour. Two incidents: a network port scan and an SSH brute force.

| | |
|---|---|
| **Date** | 2026-11-16 |
| **Target** | ShiNAS (my own NAS) |
| **Attacker** | A Kali Linux VM I control, on my own LAN |
| **Authorization** | My own equipment, my own network |
| **Goal** | Validate detection, not test resistance |
| **Related** | [Wazuh SIEM lab](wazuh.md) |

## Why I did this

Standing up a SIEM is not the same as knowing it works. So I ran two controlled attacks against my own NAS from a Kali VM, then hunted for the alerts in Wazuh. The point was to answer two questions honestly: does my SIEM see an attack, and where are the gaps?

I wrote rules of engagement first, the way a real test does:

| Rule | Reason |
|---|---|
| One target (the NAS), one attacker (Kali) | Nothing else on my network gets touched |
| Brute force uses a **fake username** and a throwaway password list | It can never succeed or lock a real account, but produces identical log evidence |
| My real password never goes in a wordlist | Wordlists get reused and left lying around |
| No exploit tools, no denial-of-service options | I am testing detection, not trying to break the NAS |
| Every action timestamped (UTC) | The timestamps are the incident timeline |
| Backup confirmed first | Standard practice before testing anything that holds real data |

A thing I want to be clear about, because it keeps the write-up honest: a scan plus a small brute force tests **detection**. It does not prove the NAS can withstand a determined attacker. "Validated detection coverage" is the claim this earns, nothing more.

## Incident 1: network port scan

**Summary:** a service and version scan of the NAS from the Kali VM. This is what an attacker does first, to inventory which services are exposed before choosing a way in.

| Field | Value |
|---|---|
| Start (UTC) | 2026-11-16 21:10:56 |
| End (UTC) | 2026-11-16 21:11:29 |
| Technique | Network reconnaissance (service/version scan) |
| Result | Scan completed, 18 open ports found across the NAS's services |

**Evidence in Wazuh:** filtering the events by the attacker's source address and the `connection_attempt` group returned only **two** alerts, both rule `11106` ("FTPD: Remote host connected to FTP server"), at level 3. The scan knocked on every port, but Wazuh only logged the one service that happens to record each connection.

**Root cause of the gap:** the Wazuh agent is **host-based**. It reads log files on the machine. A port scan is network activity that mostly never reaches any log file, so the host agent is largely blind to it. The two alerts fired only because the FTP service is chatty.

**Impact:** low on its own, but the scan revealed a large attack surface (many services listening), and the reconnaissance itself went almost entirely undetected.

**Fix and recommendation:**
- Add a network IDS (Suricata) feeding into Wazuh, so reconnaissance is caught at the network layer where it actually happens.
- Reduce the exposed surface: review which services need to listen on the LAN at all.

## Incident 2: SSH brute force

**Summary:** a small, capped SSH brute force from the Kali VM, using a username that does not exist on the NAS and six throwaway passwords. It could not succeed by design. The goal was the failed-login evidence, not access.

| Field | Value |
|---|---|
| Start (UTC) | 2026-11-16 21:14:09 |
| End (UTC) | 2026-11-16 21:14:52 (re-run at 21:22 to test the custom rule) |
| Technique | Credential access, brute force (MITRE ATT&CK T1110) |
| Result | 0 valid passwords found (as designed), full detection evidence produced |

**Evidence in Wazuh:** filtering by the attacker's source address and the `authentication_failed` group returned about **20** alerts. Each attempt tripped two rules at once: `5710` ("attempt to login using a non-existent user") and `5503` ("PAM: user login failed"), both level 5. Wazuh then **correlated** those individual failures into a single rule `5712` ("sshd: brute force trying to get access to the system") at level 10. That jump from level 5 to level 10 is the SIEM recognising a pattern, not just logging events.

**Root cause of exposure:** SSH on the NAS has password authentication enabled, and nothing rate-limits failed logins (no fail2ban, and no auto-block was triggered during the test). So a real brute force could keep guessing indefinitely. Root login is already disabled, which is good.

**Impact:** medium. Detection works well. Prevention is weak, because there is no lockout or throttle on repeated failures.

**Fix and recommendation:**
- Detection side is validated (see the custom rule below).
- Prevention side, in order of effort: move SSH to key-only authentication (disable passwords); add fail2ban or the NAS's own auto-block for repeated failures; consider a Wazuh active response to block a source address after N failures.

## The custom detection rule

Wazuh caught the brute force with rule 5712, but that rule is not tagged with a MITRE ATT&CK technique, so it never showed up in the ATT&CK dashboard. I wrote a custom rule to fix that:

```xml
<rule id="100100" level="12">
  <if_sid>5712</if_sid>
  <description>SSH brute force from $(srcip) against ShiNAS (MITRE T1110)</description>
  <mitre>
    <id>T1110</id>
  </mitre>
  <group>authentication_failures,attack,</group>
</rule>
```

How it works:
- `if_sid` 5712 means my rule only fires **after** Wazuh's built-in brute-force detection fires. I reuse all of its correlation logic instead of rebuilding it.
- `mitre` T1110 tags the alert with the Brute Force technique, so it appears in the ATT&CK dashboard and can be triaged by tactic.
- `level` 12 raises the severity above the built-in rule, because a brute force against my own NAS deserves a louder flag.

After adding it (edited on the host, copied into the manager, ownership fixed, manager restarted) and re-running the attack, rule `100100` fired at level 12 and the dashboard's MITRE ATT&CK panel lit up with **T1110 (Brute Force)** under the Credential Access tactic. This is enrichment, which is how detection engineers usually work: build on an existing rule, do not reinvent it.

## What I validated, and what I didn't

| Validated | Not validated |
|---|---|
| The SIEM detects an SSH brute force and correlates it | Whether the NAS resists a determined attacker |
| I can hunt, filter and triage alerts by source and rule | Detection of a stealthy, slow attack (this one was fast and loud) |
| I can write a detection rule mapped to MITRE ATT&CK | Network-layer reconnaissance (the host agent missed the scan) |

## Update: port-scan gap closed (Suricata)

After this report, I added [Suricata](suricata.md), a network IDS, on the NAS and fed its alerts into Wazuh. Re-running the same scan:

- The scan is now detected **two ways**: the built-in **ET SCAN "Nmap User-Agent"** rule (it spots Nmap by the User-Agent in its HTTP probes) and my own **custom SYN-threshold rule** (30+ SYNs from one source in 60 seconds), which also catches a quiet scan that never touches HTTP.
- A surprise worth recording: the default ET SCAN **network-pattern** rules stayed silent, because they only watch external→internal traffic and my Kali sits inside the LAN. The content rule and my behaviour rule are what caught it.
- Suricata on a Docker host also floods "Ethertype unknown" decoder noise; I muted just that signature with a Wazuh rule so real alerts aren't buried.

So the finding above ("host-based detection misses network recon") now has its fix in place and tested.

## What I'd harden next

- [x] Add Suricata (network IDS) into Wazuh, so port scans and other network recon are detected (done 2026-11-16, see [Suricata](suricata.md))
- [ ] Tighten SSH prevention: key-only auth, or fail2ban / NAS auto-block for repeated failures
- [ ] Add a Wazuh active response to auto-block a source after repeated brute-force hits, then re-test and document the before/after
- [ ] Run a slower, quieter brute force to see whether it stays under the 5712 correlation threshold, and tune if needed

## What I learned

- **A SIEM correlates, a logger just records.** Twenty failed logins became one "brute force" alert. That correlation is the whole value.
- **Host-based detection has a blind spot.** My agent caught the brute force but barely saw the port scan, because a scan rarely touches a log file. Knowing my own coverage gap is more useful than pretending I have none.
- **Detection and prevention are different jobs.** I proved I can *see* a brute force. I have not stopped one. Both matter, and they are separate work.
- **Enrich, don't rebuild.** Standing my custom rule on top of 5712 with `if_sid` gave me MITRE tagging and higher severity for four lines of XML.
- **Evidence needs timestamps.** Writing down the UTC start and end of each attack is what turns "I ran some tools" into an incident timeline a report can be built from.
