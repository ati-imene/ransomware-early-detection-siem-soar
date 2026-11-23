# Limitations and future work

## Limitations

- **Controlled lab**: results may not fully generalize to large, noisy production environments.
- **No long-term false-positive measurement**.
- **Rule-based correlation**: manually written rules may miss novel or heavily obfuscated attacks.
- **Telemetry gaps**: Sysmon Event ID 11 ingestion was inconsistent; network and authentication indicators were not used in scoring.
- **License constraints**: trial license data volume limits.
- **AI as assistant only**: recommendations are contextual text, not learned models.

## Improvement directions (from the thesis)

1. Integrate machine learning models to detect unknown attacks.
2. Enrich log sources (network, authentication, cloud and hybrid environments).
3. Continuously update correlation rules to follow ransomware evolution.
4. Partially automate some response actions in critical scenarios.
5. Optimize Splunk performance for high log volumes.
