# Lab architecture

The lab is a fully virtualized, isolated SOC built with **VMware Workstation**. All machines sit on an internal private subnet `10.0.0.0/24`.

| Machine | Role | IP | OS |
|---|---|---|---|
| FortiGate | Firewall / network filtering, Syslog source | 10.0.0.1 | FortiOS |
| SRV-DC | Domain controller (Active Directory, GPO) | 10.0.0.10 | Windows Server 2019 |
| SRV-FS | File server, ransomware target | 10.0.0.11 | Windows Server 2019 |
| Splunk | SIEM (collection, analysis, correlation) | 10.0.0.20 | Linux |
| SOAR | Orchestration and response platform | 10.0.0.21 | Oracle Linux 9 |
| PC0 | Client workstation (DHCP) | dynamic | Windows 11 |

## Roles

- **FortiGate**: segments the network and sends traffic logs (accept/deny, policies) to Splunk over **Syslog UDP 514**.
- **SRV-DC**: centralized identity and authentication; GPOs enable advanced audit policies:
  - File access auditing (**Event ID 4663**)
  - Process creation auditing (**Event ID 4688**)
- **SRV-FS**: hosts the shared data targeted by the simulated attack.
- **Splunk Enterprise**: central SIEM; indexes events and runs detection and correlation rules in SPL.
- **Splunk SOAR**: receives incidents via REST API and supports structured response.
- **PC0**: simulates user activity and attack steps.

## Log pipeline

1. **Splunk Universal Forwarder** installed on the monitored Windows hosts (SRV-DC, SRV-FS).
2. `inputs.conf` defines the collected channels:
   - Windows `Security`, `System`, `Application`
   - `Microsoft-Windows-Sysmon/Operational`
   - PowerShell, WMI and Task Scheduler logs when available
3. `outputs.conf` forwards data to the Splunk server on **TCP 9997**.
4. Events are stored in dedicated indexes: `windows`, `sysmon`, `edr`, `firewall`.

Example `outputs.conf` (lab values):

```ini
[tcpout]
defaultGroup = splunk_siem

[tcpout:splunk_siem]
server = 10.0.0.20:9997
```

Example `inputs.conf` (lab values):

```ini
[WinEventLog://Security]
index = windows
disabled = 0

[WinEventLog://System]
index = windows
disabled = 0

[WinEventLog://Application]
index = windows
disabled = 0

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
index = sysmon
renderXml = true
disabled = 0

[WinEventLog://Microsoft-Windows-PowerShell/Operational]
index = edr
disabled = 0
```

> Note: these configuration excerpts illustrate the setup described in the thesis; adapt them to your environment.

## Normalization

Sysmon events are stored as XML. A normalization step extracts the fields needed for correlation:
`CommandLine`, `host`, `EventCode` (plus `Image`, `ParentImage`, `User`, `ObjectName` when relevant).
