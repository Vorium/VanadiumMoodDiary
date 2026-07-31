Set-Location "D:\Batch\chroniccare"
# Check who uses entity methods
$queries = @(
    "isValidPhone",
    "bySortOrder",
    "ContactEntity\.active",
    "MoodEntryEntity\.isValidScore",
    "MoodEntryEntity\.isFull4D",
    "MoodEntryEntity\.tags",
    "MoodEntryEntity\.hasAudio",
    "CheckInEntity\.isForMedication",
    "CheckInEntity\.isPhq9",
    "CheckInEntity\.isGad7",
    "MedicationEntity\.isInUse",
    "MedicationEntity\.hasRefill",
    "MedicationEntity\.isRefillOverdue",
    "MedicationEntity\.isInRefillWindow",
    "CheckInType\.label",
    "CheckInType\.fromWire",
    "DosageUnit\.fromId",
    "HourMinute\.fromString",
    "HourMinute\.toTimeString",
    "VentEntryEntity\.hasText",
    "VentEntryEntity\.hasAudio",
    "VentEntryEntity\.isMixed",
    "VentEntryEntity\.isEmpty",
    "VentEntryEntity\.durationLabel",
    "UserProfileEntity\.hasWithdrawnConsent"
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape($q))
    $count = ($results | Measure-Object).Count
    if ($count -le 1) {
        Write-Host "Q: $q => $count (likely DEAD)" -ForegroundColor Yellow
    } else {
        Write-Host "Q: $q => $count"
        $results | Select-Object -First 2 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
    }
}
