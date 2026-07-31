Set-Location "D:\Batch\chroniccare"
# Check if ContactRepository.update / restore have any callers
foreach ($q in @("contactRepository\.update", "ContactRepository\.update", "\._contactRepo\.update", "contactRepo\.update", "ContactRepository\.restore", "contactRepository\.restore")) {
    $results = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern $q
    $count = ($results | Measure-Object).Count
    Write-Host "Q: $q => $count"
    $results | Select-Object -First 5 | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "  $rel`:$($_.LineNumber) $($_.Line.Trim())" }
}

Write-Host ""
Write-Host "=== Check ContactRepository.update abstract callers ==="
Get-ChildItem "lib" -Recurse -Filter "*.dart" | Select-String -Pattern "ContactRepository|contactRepository" | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "  $rel`:$($_.LineNumber) $($_.Line.Trim())" }
