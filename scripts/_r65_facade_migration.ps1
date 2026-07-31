# v0.27 round 65 (spen P1-11): app_database 18 facade weituo qingli
# Use MatchEvaluator to avoid PS variable interpolation of ${name}
$ErrorActionPreference = 'Stop'

Set-Location D:\Batch\chroniccare

$replacements = @(
  @{ Facade = 'watchAllCheckIns';                 Dao = 'checkInDao.watchAll' }
  @{ Facade = 'watchAssessments';                Dao = 'checkInDao.watchAssessments' }
  @{ Facade = 'watchTodayCheckIn';               Dao = 'checkInDao.watchToday' }
  @{ Facade = 'watchNormalCheckIns';             Dao = 'checkInDao.watchNormal' }
  @{ Facade = 'getLatestNormalCheckIn';          Dao = 'checkInDao.getLatestNormal' }
  @{ Facade = 'getLatestAssessmentTimestamp';    Dao = 'checkInDao.getLatestAssessmentTimestamp' }
  @{ Facade = 'insertCheckIn';                   Dao = 'checkInDao.insert' }
  @{ Facade = 'watchMedications';                Dao = 'medicationDao.watchActive' }
  @{ Facade = 'watchAllMedicationsIncludingInactive'; Dao = 'medicationDao.watchAllIncludingInactive' }
  @{ Facade = 'insertMedication';                Dao = 'medicationDao.insert' }
  @{ Facade = 'updateMedication';                Dao = 'medicationDao.update' }
  @{ Facade = 'deleteMedication';                Dao = 'medicationDao.delete' }
  @{ Facade = 'watchContacts';                   Dao = 'contactDao.watchActive' }
  @{ Facade = 'insertContact';                   Dao = 'contactDao.insert' }
  @{ Facade = 'updateContact';                   Dao = 'contactDao.update' }
  @{ Facade = 'deleteContact';                   Dao = 'contactDao.delete' }
  @{ Facade = 'watchUserProfile';                Dao = 'userProfileDao.watch' }
  @{ Facade = 'getUserProfile';                  Dao = 'userProfileDao.get' }
  @{ Facade = 'upsertUserProfile';               Dao = 'userProfileDao.upsert' }
  @{ Facade = 'watchReportHistories';            Dao = 'reportDao.watchAll' }
  @{ Facade = 'insertReportHistory';             Dao = 'reportDao.insert' }
  @{ Facade = 'deleteReportHistory';             Dao = 'reportDao.delete' }
  @{ Facade = 'clearAllReportHistories';         Dao = 'reportDao.clearAll' }
  @{ Facade = 'getAllReportHistories';           Dao = 'reportDao.getAll' }
  @{ Facade = 'watchMoodEntries';                Dao = 'moodDao.watchAll' }
  @{ Facade = 'getAllMoodEntries';               Dao = 'moodDao.getAll' }
  @{ Facade = 'watchTodayMoodEntries';           Dao = 'moodDao.watchToday' }
  @{ Facade = 'insertMoodEntry';                 Dao = 'moodDao.insert' }
  @{ Facade = 'deleteMoodEntry';                 Dao = 'moodDao.delete' }
  @{ Facade = 'watchVentEntries';                Dao = 'ventDao.watchAll' }
  @{ Facade = 'insertVentEntry';                 Dao = 'ventDao.insert' }
  @{ Facade = 'deleteVentEntry';                 Dao = 'ventDao.delete' }
)

$files = @()
$files += Get-ChildItem lib -Recurse -Filter *.dart -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch 'app_database\.dart$' } |
  Select-Object -ExpandProperty FullName
$files += Get-ChildItem test -Recurse -Filter *.dart -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty FullName

$totalChanges = 0
foreach ($file in $files) {
  $content = Get-Content $file -Raw -Encoding UTF8
  $fileChanges = 0
  foreach ($r in $replacements) {
    $daoMethod = $r.Dao  # capture in closure
    $pattern = "(?<prefix>_?db)\.$($r.Facade)\("
    $regex = [regex]$pattern
    $matchesFound = $regex.Matches($content)
    if ($matchesFound.Count -gt 0) {
      # Use MatchEvaluator to avoid PS variable interpolation of ${name}
      $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        return $m.Groups['prefix'].Value + '.' + $daoMethod + '('
      }
      $content = $regex.Replace($content, $evaluator)
      $fileChanges += $matchesFound.Count
    }
  }
  if ($fileChanges -gt 0) {
    Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline
    Write-Host "$($file | Split-Path -Leaf): $fileChanges changes"
    $totalChanges += $fileChanges
  }
}

Write-Host "===== TOTAL: $totalChanges replacements ====="
