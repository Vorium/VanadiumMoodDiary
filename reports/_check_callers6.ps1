Set-Location "D:\Batch\chroniccare"
# Check logic file usage
$logics = @{
    "StreakCalculator" = @("calculate", "shouldShowStreakBroken", "expiryThresholdHours")
    "CareEngine" = @("evaluate", "fire", "_build", "CareTrigger", "CareTriggerType")
    "isLateCheckInHabit" = @()
    "isWeekendMissed" = @()
    "isWeekPerfect" = @()
    "isSecondDayMissed" = @()
    "CareCopy" = @("forTrigger")
    "Phq9Scale" = @("id", "displayName", "shortDescription", "instruction", "items", "options", "totalRange", "severityCutoffs", "computeResult", "detectCrisis", "phq9Scale")
    "Gad7Scale" = @("id", "displayName", "shortDescription", "instruction", "items", "options", "totalRange", "severityCutoffs", "computeResult", "detectCrisis", "gad7Scale")
    "AssessmentScale" = @("id", "displayName", "items", "options", "totalRange", "severityCutoffs", "computeResult", "detectCrisis")
    "AssessmentRecord" = @("tryFromEntity", "scaleId", "timestamp", "total", "scores")
    "AssessmentComparisonCalculator" = @("severityRankFor", "severityLabelFor", "fromRecords", "historyFromRecords", "_daysBetween")
    "allScales" = @()
    "scaleById" = @()
    "DayDetailCalculator" = @("fromData")
    "ReminderScheduler" = @("shouldSendAlert", "hoursSinceLastCheckIn", "selectFirstContact", "selectAllActiveContacts")
    "MedicationReport" = @("compute", "toReportString", "adherencePct")
    "MedicationStatCalculator" = @("calculate")
    "MissedDateBuilder" = @("build")
    "TempEntryExtractor" = @("extract")
    "EmailTemplate" = @("buildSubject", "buildBody", "_formatDateTime")
    "ChineseHolidays" = @("isHoliday", "nextWorkdayAfter")
    "TrendCalculator" = @("dailyBreakdown", "monthlyBreakdown", "streakSummary", "_longestStreak", "_uniqueDays", "monthlyCalendar", "shiftMonth", "_dateOnly", "_monthKey", "DailyCheckIn", "MonthlyCheckIn", "StreakSummary", "CalendarDay", "CalendarMonth")
    "hotlineByRegion" = @()
    "HotlineRegion" = @()
}
foreach ($sym in $logics.Keys) {
    Write-Host "=== $sym ==="
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape($sym))
    $count = ($results | Measure-Object).Count
    Write-Host "  total references: $count"
    $results | Select-Object -First 3 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "    $rel`:$($_.LineNumber) $($_.Line.Trim())" }
}
