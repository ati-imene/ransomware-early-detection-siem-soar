# Experimental scenario: pre-encryption ransomware behaviour

The goal is **not** to run real ransomware, but to reproduce, in a controlled way, the most representative technical behaviours of the **pre-encryption phase**, and check that each one is visible in the SIEM.

Three objectives:
1. Validate the log collection chain (Windows hosts and FortiGate → Splunk).
2. Verify that behavioural indicators reveal ransomware-like activity **before** mass encryption.
3. Build a correlation and alerting logic usable by an automated response process (SOAR).

## Step 1: Encoded PowerShell execution

- **Behaviour**: obfuscated command via `powershell.exe -EncodedCommand`.
- **ATT&CK**: T1059.001 (PowerShell)
- **Telemetry**: PowerShell Script Block Logging (**Event ID 4104**) shows the decoded script content.
- **Query**: [`splunk/searches/01_powershell_4104.spl`](../splunk/searches/01_powershell_4104.spl)

## Step 2: Shadow copy deletion

- **Behaviour**: `vssadmin delete shadows /all /quiet` prevents restoring files.
- **ATT&CK**: T1490 (Inhibit System Recovery), Defense Evasion context
- **Telemetry**: Sysmon Event ID 1, Security 4688
- **Query**: [`splunk/searches/02_vssadmin.spl`](../splunk/searches/02_vssadmin.spl)

## Step 3: Mass file activity (pre-encryption)

- **Behaviour**: 200 files created quickly in a shared folder on SRV-FS.
- **ATT&CK**: TA0040 Impact, precursor of T1486 (Data Encrypted for Impact)
- **Telemetry**:
  - Windows Security **Event ID 4663** (file access/modification/deletion), the main and most stable source
  - Sysmon **Event ID 11** (FileCreate), complementary
- **Observation**: Sysmon 11 visibility in Splunk was inconsistent (dependent on the Sysmon configuration and ingestion), so the analysis relied mainly on 4663.
- **Queries**: [`splunk/searches/03_file_activity.spl`](../splunk/searches/03_file_activity.spl)

## Step 4: Recovery mechanisms disabled

- **Behaviour**: `bcdedit /set {default} recoveryenabled No`
- **ATT&CK**: T1490
- **Telemetry**: Sysmon Event ID 1
- **Query**: [`splunk/searches/04_bcdedit.spl`](../splunk/searches/04_bcdedit.spl)

## Step 5: Log clearing

- **Behaviour**: `wevtutil cl Security` erases the Security log to hide traces.
- **ATT&CK**: T1070.001 (Indicator Removal: Clear Windows Event Logs)
- **Telemetry**: Sysmon Event ID 1
- **Query**: [`splunk/searches/05_wevtutil.spl`](../splunk/searches/05_wevtutil.spl)

## Indicators used

| Type | Used | Sources |
|---|---|---|
| Host-based | ✅ | Sysmon 1, PowerShell 4104, Sysmon 13 (registry) |
| File activity | ✅ | Security 4663 (+ Sysmon 11) |
| Network | Collected, not prioritized | FortiGate Syslog |
| Authentication | Not used | Scenario does not cover initial access or lateral movement |

The combination of these indicators (critical commands, system modification, sensitive file access) feeds the multi-event correlation.
