Set-Location "D:\Batch\chroniccare"
# Check how startDate is set in setup form
$results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern "MedicationDraft\("
$results | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "  $rel`:$($_.LineNumber) $($_.Line.Trim())" }
