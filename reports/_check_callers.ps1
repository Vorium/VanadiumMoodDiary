Set-Location "D:\Batch\chroniccare"
$methods = @("watchAll", "watchAssessments", "watchToday", "watchNormalCheckIns", "getLatestNormalCheckIn", "getLatestAssessmentTimestamp", "addTempMedication", "saveAssessment")
foreach ($m in $methods) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape(".$m("))
    $count = ($results | Measure-Object).Count
    $samples = $results | Select-Object -First 3 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; "$rel`:$($_.LineNumber)" }
    $samplesStr = $samples -join " | "
    Write-Host "checkInRepo.$m`: $count callers. $samplesStr"
}
