# Run solution initialization only if key solution artifacts are missing.

$requiredFiles = @(
    'Customizations.xml',
    'Relationships.xml',
    'Solution.xml'
)

$missing = @()

foreach ($file in $requiredFiles) {
    $found = Get-ChildItem -Path . -Recurse -File -Filter $file -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $found) {
        $missing += $file
    }
}

if ($missing.Count -eq 0) {
    Write-Host "Solution artifacts already present (Customizations.xml, Relationships.xml, Solution.xml). Skipping InitializeSolution."
    return
}

Write-Host "Missing solution artifacts: $($missing -join ', '). Running InitializeSolution..."
& (Join-Path $PSScriptRoot 'InitializeSolution.ps1')
if ($LASTEXITCODE -ne 0) {
    Write-Error "InitializeSolution.ps1 failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
