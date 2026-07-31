Set-Location "D:\Batch\chroniccare"
# Check who uses entity methods
$queries = @(
    "\.isValidPhone",
    "\.bySortOrder",
    "\.active(?!\.length)",
    "\.isValidScore",
    "\.isFull4D",
    "\.isPhq9",
    "\.isGad7",
    "\.isInUse",
    "\.hasRefill",
    "\.isRefillOverdue",
    "\.isInRefillWindow",
    "CheckInType\.label",
    "CheckInType\.fromWire",
    "DosageUnit\.fromId",
    "HourMinute\.fromString",
    "HourMinute\.toTimeString",
    "\.hasText",
    "\.hasAudio",
    "\.isMixed",
    "VentEntryEntity\.isEmpty",
    "\.durationLabel",
    "\.hasWithdrawnConsent",
    "\.isForMedication",
    "RemindersHubService",
    "computeRefillFireTime",
    "ReminderCheckResult\.empty"
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $q
    $count = ($results | Measure-Object).Count
    if ($count -le 1) {
        Write-Host "Q: $q => $count (likely DEAD)" -ForegroundColor Yellow
    } else {
        Write-Host "Q: $q => $count"
        $results | Select-Object -First 2 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
    }
}
