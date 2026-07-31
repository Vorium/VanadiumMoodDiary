Set-Location "D:\Batch\chroniccare"
# Find which classes are used OUTSIDE their own file
$checks = @{
    "AssessmentRecord"             = "lib\domain\logic\assessment_record.dart"
    "AssessmentComparison"         = "lib\domain\logic\assessment_comparison.dart"
    "AssessmentComparisonCalculator" = "lib\domain\logic\assessment_comparison.dart"
    "AssessmentHistory"            = "lib\domain\logic\assessment_comparison.dart"
    "AssessmentResult"             = "lib\domain\logic\assessment_scale.dart"
    "CrisisSignal"                 = "lib\domain\logic\assessment_scale.dart"
    "SeverityCutoff"               = "lib\domain\logic\assessment_scale.dart"
    "AssessmentItem"               = "lib\domain\logic\assessment_scale.dart"
    "TrendCalculator"              = "lib\domain\logic\trend_calculator.dart"
    "DailyCheckIn"                 = "lib\domain\logic\trend_calculator.dart"
    "MonthlyCheckIn"               = "lib\domain\logic\trend_calculator.dart"
    "StreakSummary"                = "lib\domain\logic\trend_calculator.dart"
    "CalendarDay"                  = "lib\domain\logic\trend_calculator.dart"
    "CalendarMonth"                = "lib\domain\logic\trend_calculator.dart"
    "EmailTemplate"                = "lib\domain\logic\email_template.dart"
    "CareTrigger"                  = "lib\domain\logic\care_engine.dart"
    "CareTriggerType"              = "lib\domain\logic\care_engine.dart"
    "DayDetail"                    = "lib\domain\logic\day_detail.dart"
    "DayEvent"                     = "lib\domain\logic\day_detail.dart"
    "DayEventKind"                 = "lib\domain\logic\day_detail.dart"
    "MedicationReportData"         = "lib\domain\logic\medication_report.dart"
    "MedicationStat"               = "lib\domain\logic\medication_report.dart"
    "TempMedEntry"                 = "lib\domain\logic\medication_report.dart"
    "MedicationStatCalculator"     = "lib\domain\logic\medication_stat_calculator.dart"
    "MissedDateBuilder"            = "lib\domain\logic\medication_stat_calculator.dart"
    "TempEntryExtractor"           = "lib\domain\logic\temp_entry_extractor.dart"
    "ComparisonTrend"              = "lib\domain\logic\assessment_comparison.dart"
}
foreach ($sym in $checks.Keys) {
    $ownFile = $checks[$sym]
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape($sym))
    $otherFiles = $results | Where-Object { $_.Path -ne $ownFile } | ForEach-Object { $_.Path } | Sort-Object -Unique
    if ($otherFiles.Count -eq 0) {
        Write-Host "DEAD: $sym (only own file)" -ForegroundColor Yellow
    } else {
        Write-Host "OK: $sym => $($otherFiles.Count) other files"
        $otherFiles | Select-Object -First 3 | ForEach-Object { $rel = $_ -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "  $rel" }
    }
}
