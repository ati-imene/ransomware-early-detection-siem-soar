# Results

## Detection

- The **5 simulated steps** were all detected in Splunk.
- On the target file server (SRV-FS), the correlation search grouped **27 matched events** into a single multi-step detection.
- **7 suspicious behaviours** were identified on the host:
  - File Activity (4663)
  - T1059 – PowerShell
  - T1070 – Log Clearing
  - T1490 – Recovery Modification
  - T1490 – Shadow Copy Deletion
  - T1547 – Registry Persistence
  - T1562 – Defense Evasion
- Score: **total 540 / 540 → normalized 100.00**, severity **Critical**.
- Generated action: **`isolate_host`**, with the playbook *Isolation + Evidence Collection + Escalation*.

### Note on run-to-run variation

The number of correlated techniques varied between test runs because some events were **not always indexed** in Splunk in time (indexing delays and gaps, also observed with Sysmon Event ID 11). Runs with fewer indexed behaviours produced lower scores, which is consistent with the scoring model. The result above is the run where all behaviours were indexed.

### Note on the SOAR artifact

The SOAR artifact screenshot in the thesis uses **example values** set in `send_to_soar.ps1` (score 100, one technique). Passing the fields computed by Splunk dynamically to SOAR is a planned improvement.

Many alerts were triggered during testing. These are **not false positives**: they come from an intensive test phase in which attack scenarios were replayed many times to evaluate robustness.

## Detection time (MTTD)

Correlation searches run **every 5 minutes**, so suspicious behaviour is surfaced shortly after it appears, before the encryption phase.

## Response automation (MTTR)

- Incident created in SOAR **automatically, with no manual action**.
- Delay observed between detection in Splunk and incident creation in SOAR: **about 3 minutes**.
- Full chain executed: suspicious events → correlation → PowerShell script → REST API → SOAR container → severity classification → artifact with recommendation.

Some longer delays seen during testing came from human interaction (time to open SOAR and check results), not from the pipeline itself.

## Decision support

Each artifact includes a `playbook_suggestion` built from the detected techniques and the risk score (e.g. "analyze PowerShell activity, check file access 4663, investigate persistence").
These actions are **not executed automatically**: this keeps a human in the loop and avoids harmful actions on false positives.

## Comparison

| Criterion | Traditional approach | Proposed system |
|---|---|---|
| Detection moment | Post-encryption | Pre-encryption |
| Analysis type | Single event | Multi-event correlation |
| False positives | High | Reduced |
| Detection time (MTTD) | Medium | Low |
| Response time (MTTR) | Manual | Automated |
| Prioritization | Limited | Scoring-based |
| Response | Manual | Semi-automated |
| AI assistance | Absent | Present |

## Implementation difficulties and fixes

| Difficulty | Fix |
|---|---|
| PowerShell scripts failing when launched from Splunk | `.cmd` wrapper calling PowerShell with the right parameters |
| SOAR API errors (400 Bad Request) | Corrected and structured JSON payload |
| Duplicate incidents (static `source_data_identifier`) | Dynamic identifier based on a timestamp |
| PowerShell syntax errors | Script corrected and validated |
| Splunk ↔ SOAR integration | Correct API headers and endpoints, TLS 1.2 enabled |
| AI limited to assistance | Added `playbook_suggestion` field (decision support, not autonomous) |
