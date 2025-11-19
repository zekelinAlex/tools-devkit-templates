$name = Split-Path -Leaf (Get-Location)
$csproj = "$name.csproj"

pac package init --package-name $name 

$content = Get-Content $csproj -Raw
$content = $content -replace '<PackageReference Include="Microsoft\.PowerApps\.MSBuild\.PDPackage" Version="1.*">', '<PackageReference Include="TALXIS.PowerApps.MSBuild.PDPackage" Version="0.0.1">'
Set-Content -Path $csproj -Value $content -NoNewline