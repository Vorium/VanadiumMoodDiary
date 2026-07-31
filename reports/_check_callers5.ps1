Set-Location "D:\Batch\chroniccare"
# Check use case usage
foreach ($uc in @("RecordCheckInUseCase", "RecordTempMedicationUseCase", "TriggerReminderUseCase")) {
    Write-Host "=== $uc ==="
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $uc
    $results | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "  $rel`:$($_.LineNumber) $($_.Line.Trim())" }
}
