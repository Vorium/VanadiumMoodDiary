Set-Location "D:\Batch\chroniccare"
# Check MoodEntryDraft usage
$queries = @(
    "MoodEntryDraft",
    "MedicationDraft\(",
    "MedicationDraft\.",
    "MoodEntryDraft\.",
    "MedicationDraft copyWith",
    "MoodEntryDraft copyWith"
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape($q))
    $count = ($results | Measure-Object).Count
    Write-Host "Q: $q => $count"
    $results | Select-Object -First 5 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
}
