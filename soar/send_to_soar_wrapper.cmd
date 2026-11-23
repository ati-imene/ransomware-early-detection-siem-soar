@echo off
REM Wrapper launched by the Splunk alert action ("Run a script").
REM Running PowerShell directly from Splunk failed because of the execution
REM environment and policies, so this wrapper starts it with the right parameters.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Splunk\etc\apps\search\bin\scripts\send_to_soar.ps1"
