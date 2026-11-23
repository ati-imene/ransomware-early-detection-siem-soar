# Response playbooks

Each severity level maps to a recommended response action and a playbook.
Recommendations are attached to the SOAR incident as **decision support**: critical actions (isolation, process termination) are validated by the SOC analyst, never executed blindly.

| Severity | Score | Response action | Playbook | Steps |
|---|---|---|---|---|
| **Critical** | ≥ 80 | `isolate_host` | Isolation + Evidence Collection + Escalation | 1. Isolate the host from the network · 2. Collect evidence (memory, logs, file list) · 3. Escalate to senior SOC / incident response |
| **High** | ≥ 50 | `kill_process_and_alert_soc` | Process Termination + Analyst Review | 1. Identify and stop the suspicious process · 2. Alert the SOC · 3. Analyst reviews the chain of events |
| **Medium** | ≥ 30 | `alert_soc` | Alert + Investigation | 1. Raise a SOC alert · 2. Investigate PowerShell commands, file access (4663), persistence |
| **Low** | < 30 | `monitor` | Monitoring | Keep the host under watch, no action |

## Incident flow in SOAR

1. Splunk alert fires (score above threshold).
2. `send_to_soar.ps1` posts a **container** to `/rest/container`.
3. SOAR creates the incident with:
   - name, label, severity
   - an **artifact** containing host, techniques, unique techniques, scores, response action
   - a `playbook_suggestion` field (contextual recommendation)
4. The analyst reviews the artifact and decides on the critical actions.

## Why human-in-the-loop?

A single detected technique is not enough to confirm a real attack. When only one technique is present, the analyst starts with investigation, even if isolation is suggested. This balance between automation and human control follows good SOC practice and avoids harmful actions on false positives.
