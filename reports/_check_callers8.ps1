Set-Location "D:\Batch\chroniccare"
$queries = @(
    "shouldShowStreakBroken",
    "StreakCalculator\.",
    "isLateCheckInHabit",
    "isWeekendMissed",
    "isWeekPerfect",
    "isSecondDayMissed",
    "EmailTemplate\.",
    "selectFirstContact",
    "selectAllActiveContacts",
    "shouldSendAlert",
    "hoursSinceLastCheckIn",
    "isValidPhone",
    "bySortOrder",
    "isRefillOverdue",
    "isInRefillWindow",
    "isInUse",
    "hasRefill",
    "severityRankFor",
    "severityLabelFor",
    "historyFromRecords",
    "fromRecords",
    "adherencePct",
    "toReportString",
    "MonthlyCheckIn",
    "CalendarDay\(",
    "CalendarMonth\(",
    "DailyCheckIn\(",
    "StreakSummary\(",
    "MedicationStat\(",
    "TempMedEntry\(",
    "MedicationReportData\(",
    "DayDetail\(",
    "DayEvent\(",
    "AssessmentRecord\(",
    "AssessmentHistory\(",
    "AssessmentComparison\(",
    "scaleById",
    "allScales",
    "nextWorkdayAfter",
    "isHoliday"
)
foreach ($q in $queries) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape($q))
    $count = ($results | Measure-Object).Count
    if ($count -gt 0) {
        Write-Host "Q: $q => $count"
        $results | Select-Object -First 2 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
    } else {
        Write-Host "Q: $q => 0 (DEAD)" -ForegroundColor Yellow
    }
}
