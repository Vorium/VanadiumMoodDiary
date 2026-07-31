Set-Location "D:\Batch\chroniccare"
# Check entity properties more carefully
$queries = @(
    "mood\.tags",
    "mood\.hasAudio",
    "entry\.tags",
    "entry\.hasText",
    "entry\.isMixed",
    "entry\.isEmpty",
    "VentEntryEntity\.isEmpty",
    "VentEntryEntity\.isMixed"
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $q
    $count = ($results | Measure-Object).Count
    Write-Host "Q: $q => $count"
    $results | Select-Object -First 3 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
}
