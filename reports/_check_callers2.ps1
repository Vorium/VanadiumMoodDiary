Set-Location "D:\Batch\chroniccare"
# Check various repository methods for dead code
$repos = @{
    "ContactRepository"    = @("watchAll", "add", "update", "delete", "restore")
    "MedicationRepository" = @("watchAll", "watchAllIncludingInactive", "add", "update", "setActive", "delete", "updateRefill")
    "MoodRepository"       = @("watchAll", "watchToday", "add", "delete")
    "VentRepository"       = @("watchAll", "add", "delete", "getById", "restore")
    "UserProfileRepository" = @("watch", "get", "save", "updateLastCheckIn", "recordConsent", "withdrawConsent", "resetConsent")
    "ReportHistoryRepository" = @("watchAll", "getAll", "delete", "clearAll", "insert")
}
foreach ($repo in $repos.Keys) {
    Write-Host "`n=== $repo ==="
    foreach ($m in $repos[$repo]) {
        $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern "\.$m\("
        $count = ($results | Measure-Object).Count
        $samples = $results | Select-Object -First 3 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; "$rel`:$($_.LineNumber)" }
        $samplesStr = $samples -join " | "
        Write-Host "  $m`: $count callers. $samplesStr"
    }
}
