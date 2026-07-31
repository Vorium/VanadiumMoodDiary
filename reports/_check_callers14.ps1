Set-Location "D:\Batch\chroniccare"
# Check DateTime.now() calls in domain layer
$results = Get-ChildItem "lib\domain" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern "DateTime\.now\(\)|DateTime\([0-9]+, [0-9]+, [0-9]+\)|DateTime\([a-z]+\.[a-z]+, [a-z]+\.[a-z]+, [a-z]+\.[a-z]+\)"
$results | ForEach-Object { $rel = $_.Path -replace [regex]::Escape("D:\Batch\chroniccare\"), ""; Write-Host "  $rel`:$($_.LineNumber) $($_.Line.Trim())" }

Write-Host ""
Write-Host "=== DateTime.now() in test/domain ==="
$results2 = Get-ChildItem "test\domain" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | Select-String -Pattern "DateTime\.now\(\)"
$count2 = ($results2 | Measure-Object).Count
Write-Host "Total: $count2"
