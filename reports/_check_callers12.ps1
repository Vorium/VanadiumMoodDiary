Set-Location "D:\Batch\chroniccare"
# More entity method usage
$queries = @(
    "\.isValidPhone",
    "ContactEntity\.bySortOrder",
    "ContactEntity\.active",
    "\.isValidScore",
    "\.isFull4D",
    "\.isPhq9",
    "\.isGad7",
    "CheckInType\.label",
    "CheckInType\.fromWire",
    "DosageUnit\.fromId",
    "HourMinute\.fromString",
    "\.toTimeString",
    "\.isMixed",
    "\.isEmpty\b",
    "VentEntryEntity\.isEmpty",
    "userProfile\.hasWithdrawnConsent",
    "profile\.hasWithdrawnConsent",
    "\.hasWithdrawnConsent",
    "\.isForMedication"
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $q
    $count = ($results | Measure-Object).Count
    Write-Host "Q: $q => $count"
    $results | Select-Object -First 3 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
}
