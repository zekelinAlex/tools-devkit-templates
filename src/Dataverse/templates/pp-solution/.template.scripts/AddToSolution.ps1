$ErrorActionPreference = 'Continue'

try {
    $csproj = Get-ChildItem -Path . -Filter '*.csproj' -File -ErrorAction SilentlyContinue |
              Select-Object -First 1
    if (-not $csproj) { exit 0 }

    # Walk up to find the .slnx (preferred) or .sln the engine likely added us to.
    $slnFile  = $null
    $dir      = (Get-Location).Path
    $maxDepth = 10
    for ($i = 0; $i -lt $maxDepth; $i++) {
        $hit = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Extension -in @('.slnx', '.sln') } |
               Sort-Object @{ Expression = { if ($_.Extension -eq '.slnx') { 0 } else { 1 } } }, Name |
               Select-Object -First 1
        if ($hit) { $slnFile = $hit; break }

        $parent = Split-Path -Path $dir -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $dir) { break }
        $dir = $parent
    }

    if (-not $slnFile) { exit 0 }

    Write-Host "Project '$($csproj.Name)' has been added to '$($slnFile.Name)'."
    Write-Host "Solution file: $($slnFile.FullName)"
}
catch {
    # Swallow — announcement is convenience only.
}

exit 0
