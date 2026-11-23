<#
.SYNOPSIS
    Sends a Splunk correlation alert to Splunk SOAR as a new container (incident) with an artifact.

.DESCRIPTION
    Called by send_to_soar_wrapper.cmd when the Splunk alert fires.
    Builds a JSON payload (incident name, severity, detected techniques, risk score,
    recommended action, playbook suggestion) and posts it to the SOAR REST API.
    A dynamic source_data_identifier (timestamp) prevents duplicate incidents.

    Lab version cleaned for publication: the API token is read from an environment
    variable and never stored in the script.

    Note: the artifact values below are EXAMPLE values (as used in the thesis demo).
    Next step: read the fields computed by the Splunk correlation search and pass them dynamically.

.NOTES
    Lab use. Certificate validation is disabled because the lab SOAR uses a self-signed certificate.
    Do NOT do this in production.
#>

# --- Configuration ---------------------------------------------------------
$SOAR_URL   = "https://10.0.0.21:8443/rest/container"   # lab SOAR endpoint
$SOAR_TOKEN = $env:SOAR_AUTH_TOKEN                        # set this variable on the Splunk host

if (-not $SOAR_TOKEN) {
    Write-Host "ERROR: SOAR_AUTH_TOKEN environment variable is not set."
    exit 1
}

# TLS 1.2 + accept the lab's self-signed certificate
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Unique identifier to avoid duplicate containers
$source_id = "splunk-" + (Get-Date -Format "yyyyMMddHHmmss")

$headers = @{
    "ph-auth-token" = $SOAR_TOKEN
    "Content-Type"  = "application/json"
}

# --- Payload ---------------------------------------------------------------
$bodyObject = @{
    name                   = "Ransomware Pre-Encryption Multi-Step Correlation"
    label                  = "events"
    severity               = "high"
    source_data_identifier = $source_id
    description            = "Alert from Splunk correlation rule"
    artifacts              = @(
        @{
            name = "Ransomware Correlation Artifact"
            label = "event"
            cef  = @{
                host                = "SRV-FS"
                alert_name          = "Ransomware Pre-Encryption Multi-Step Correlation"
                alert_type          = "correlation"
                matched_events      = "1"
                techniques          = "T1059 - PowerShell"
                unique_techniques   = "1"
                total_score         = "100"
                normalized_score    = "100"
                response_action     = "isolate_host"
                playbook_suggestion = "AI Recommendation: Possible ransomware pre-encryption activity detected. Suggested actions: isolate host, analyze PowerShell activity, check file access 4663, and investigate persistence techniques."
            }
        }
    )
}

$body = $bodyObject | ConvertTo-Json -Depth 6

# --- Send ------------------------------------------------------------------
try {
    $response = Invoke-RestMethod -Uri $SOAR_URL -Method Post -Headers $headers -Body $body
    Write-Host "SUCCESS"
    $response
}
catch {
    Write-Host "ERROR"
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        Write-Host $reader.ReadToEnd()
    }
}
