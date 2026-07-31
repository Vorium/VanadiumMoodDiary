Set-Location "D:\Batch\chroniccare"
# Be more precise - find specific method invocations
$queries = @(
    "MedicationRepository.*\.setActive\(",
    "medicationRepository.*\.setActive\(",
    "_medicationRepo.*\.setActive\(",
    "repo\.setActive\("
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $q
    $count = ($results | Measure-Object).Count
    $samples = $results | Select-Object -First 5 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; "$rel`:$($_.LineNumber) $($_.Line.Trim())" }
    $samplesStr = $samples -join " | "
    Write-Host "Q: $q => $count"
    Write-Host "  $samplesStr"
}

Write-Host ""
Write-Host "=== Searching for withdrawConsent / resetConsent ==="
foreach ($q in @("withdrawConsent", "resetConsent")) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $q
    $count = ($results | Measure-Object).Count
    $samples = $results | Select-Object -First 5 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; "$rel`:$($_.LineNumber) $($_.Line.Trim())" }
    $samplesStr = $samples -join " | "
    Write-Host "Q: $q => $count"
    Write-Host "  $samplesStr"
}
