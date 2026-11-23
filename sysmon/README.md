# Telemetry: monitored events

Sysmon (Sysinternals) was deployed on the Windows hosts (file server and clients) with a custom configuration to keep relevant events and reduce noise. Events are written to `Microsoft-Windows-Sysmon/Operational` and collected by the Splunk Universal Forwarder.

## Sysmon

| Event ID | Name | Why it matters for ransomware |
|---|---|---|
| 1 | Process Create | Suspicious executions: encoded PowerShell, `vssadmin`, `bcdedit`, `wevtutil` |
| 3 | Network Connection | Possible command-and-control (C2) communication |
| 11 | File Create | Mass file creation before or during encryption |
| 13 | Registry Value Set | Persistence or system modification |

## Windows (enabled through GPO on the domain controller)

| Event ID | Name | Use |
|---|---|---|
| 4663 | Object access (files) | Mass read/modify/delete on the file share, main file-activity source |
| 4688 | Process creation | Process execution audit |
| 4104 | PowerShell Script Block Logging | Decoded content of executed scripts (T1059.001) |

## Network

FortiGate firewall logs sent to Splunk over Syslog (UDP 514): accepted/denied connections and applied policies.
