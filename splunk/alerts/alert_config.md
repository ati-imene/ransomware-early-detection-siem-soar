# Splunk alert configuration

| Setting | Value |
|---|---|
| Name | Ransomware Pre-Encryption Multi-Step Correlation |
| Search | [`../correlation/ransomware_multistep_correlation.spl`](../correlation/ransomware_multistep_correlation.spl) |
| Alert type | Scheduled |
| Schedule | Cron `*/5 * * * *` (every 5 minutes) |
| Time range | Last 5 minutes |
| Trigger condition | Number of results > 0 |
| Trigger | Once |
| Actions | Add to Triggered Alerts · Run a script: `send_to_soar_wrapper.cmd` |

The script must be placed in `$SPLUNK_HOME/bin/scripts` (or the app's `bin/scripts` folder).

> Note: the "Run a script" alert action is deprecated in recent Splunk versions. A custom alert action is the recommended long-term replacement.
