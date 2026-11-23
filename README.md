# Early Ransomware Detection & Automated Response (SIEM / SOAR)

> Detecting ransomware **before encryption** through multi-event correlation aligned with MITRE ATT&CK, dynamic risk scoring, and automated incident creation in SOAR.

**Applied research project — M.Eng. in Telecommunication Networks, École de technologie supérieure (ÉTS), Montréal**

Author: Imene Ati · 2023–2026

---

## 🎯 Problem

Traditional security architectures often react **too late** to ransomware: by the time a single-event signature fires, files are already encrypted.
This project focuses on the **pre-encryption phase** and asks:

1. Can we detect the behaviours that *precede* encryption (encoded PowerShell, shadow copy deletion, recovery tampering, log clearing, mass file access)?
2. Can we turn that detection into a **structured, prioritized incident** automatically, without manual work, while keeping the analyst in control of critical actions?

## 🏗️ Architecture

```
 ┌──────────┐   ┌──────────┐   ┌──────────┐
 │  SRV-DC  │   │  SRV-FS  │   │   PC0    │   Windows hosts
 │ AD / GPO │   │  target  │   │  client  │   Sysmon + Windows Security + PowerShell 4104
 └────┬─────┘   └────┬─────┘   └────┬─────┘
      │  Splunk Universal Forwarder (TCP 9997)
      ▼              ▼              ▼
 ┌─────────────────────────────────────────┐      ┌──────────────┐
 │        Splunk Enterprise (SIEM)         │◄─────│  FortiGate   │ Syslog UDP 514
 │ indexes: windows · sysmon · edr · fw    │      │   firewall   │
 │ multi-event correlation + risk scoring  │      └──────────────┘
 └───────────────────┬─────────────────────┘
                     │ scheduled alert (every 5 min) → run script
                     ▼
        send_to_soar_wrapper.cmd → send_to_soar.ps1
                     │ REST API (JSON, TLS 1.2)
                     ▼
 ┌─────────────────────────────────────────┐
 │              Splunk SOAR                │
 │ container + artifacts + severity +      │
 │ playbook suggestion (decision support)  │
 └─────────────────────────────────────────┘
```

Fully virtualized and isolated lab (VMware Workstation), private subnet `10.0.0.0/24`.
Details: [docs/architecture.md](docs/architecture.md)

## ⚔️ Simulated attack chain (pre-encryption)

| Step | Action simulated | MITRE ATT&CK | Main telemetry |
|---|---|---|---|
| 1 | Encoded PowerShell execution | T1059.001 | PowerShell 4104, Sysmon 1 |
| 2 | Shadow copy deletion (`vssadmin`) | T1490 | Sysmon 1, Security 4688 |
| 3 | Mass file activity on file share (200 files) | T1486 (precursor) | Security 4663, Sysmon 11 |
| 4 | Recovery disabled (`bcdedit`) | T1490 | Sysmon 1 |
| 5 | Security log clearing (`wevtutil`) | T1070.001 | Sysmon 1 |

Details: [docs/attack-scenario.md](docs/attack-scenario.md) · Lab-only commands: [simulation/](simulation/)

## 🧠 Detection & scoring

- **Multi-event correlation** in SPL: each matching event is mapped to an ATT&CK technique, then techniques are aggregated **per host**.
- **Dynamic risk score** based on the number of distinct techniques observed, normalized to 0–100.
- **4 severity levels**, each tied to a response action and a playbook:

| Normalized score | Severity | Suggested action | Playbook |
|---|---|---|---|
| ≥ 80 | Critical | `isolate_host` | Isolation + Evidence collection + Escalation |
| ≥ 50 | High | `kill_process_and_alert_soc` | Process termination + Analyst review |
| ≥ 30 | Medium | `alert_soc` | Alert + Investigation |
| < 30 | Low | `monitor` | Monitoring |

Query: [splunk/correlation/ransomware_multistep_correlation.spl](splunk/correlation/ransomware_multistep_correlation.spl)

## ⚙️ Automated response (SIEM → SOAR)

- Splunk alert scheduled **every 5 minutes**, triggered when results > 0.
- Alert action runs a `.cmd` wrapper that launches a PowerShell script.
- The script builds a JSON container + artifact (techniques, score, severity, recommendation) and posts it to the **SOAR REST API**, with a dynamic `source_data_identifier` to avoid duplicates.
- A `playbook_suggestion` field gives the analyst a contextual recommendation. **Critical actions are never executed automatically**: the analyst validates them.

Code: [soar/](soar/)

## 📊 Results

- All **5 simulated steps were detected**.
- **27 matched events** on the target file server, **7 suspicious behaviours** (T1059, T1070, T1490 ×2, T1547, T1562, file activity 4663) → **score 540/540, normalized 100 (Critical)**.
- Scores varied between runs when some events were not indexed in time; see [docs/results.md](docs/results.md).
- Incident created and documented **automatically** in SOAR, about **3 minutes** after detection, with no manual intervention.
- Recommended action generated: host isolation, with evidence collection and SOC escalation.

| Criterion | Traditional approach | Proposed system |
|---|---|---|
| Detection moment | Post-encryption | **Pre-encryption** |
| Analysis | Single event | **Multi-event correlation** |
| Prioritization | Limited | **Risk scoring** |
| Response | Manual | **Semi-automated** |
| Decision support | None | **Present** |

Details: [docs/results.md](docs/results.md)

## ⚠️ Limitations & future work

Honest limits identified during the experiment:

- Controlled lab environment; no long-term false-positive measurement.
- Hand-written correlation rules may miss novel or heavily obfuscated attacks.
- Indexing was not always complete in time (e.g. Sysmon Event ID 11), so the correlation score varied between runs; Security 4663 was used as the main file-activity source.
- The SOAR script sends example score values; passing Splunk's computed fields dynamically is a next step.
- Trial license volume constraints.

**Future work:** machine learning for unknown attacks, richer log sources, and further response automation.
See [docs/limitations-and-future-work.md](docs/limitations-and-future-work.md)

## 📁 Repository structure

```
├── docs/            architecture, scenario, results, limitations
├── splunk/
│   ├── searches/      SPL queries per attack step
│   ├── correlation/   multi-step correlation + risk scoring
│   └── alerts/        alert configuration
├── soar/            wrapper + PowerShell script to SOAR REST API, playbooks
├── sysmon/          monitored event IDs
└── simulation/      lab-only attack simulation steps
```

## 🇫🇷 Résumé

Projet de maîtrise (ÉTS) : détection précoce des rançongiciels en phase de pré-chiffrement grâce à une corrélation multi-événements alignée sur MITRE ATT&CK, un score de risque dynamique à 4 niveaux de sévérité, et la création automatique d'incidents dans Splunk SOAR via API REST (≈ 3 minutes entre détection et incident). L'analyste garde le contrôle des actions critiques.

---

⚠️ *Educational and research use only. The simulation commands are destructive and must only be run in an isolated lab.*
