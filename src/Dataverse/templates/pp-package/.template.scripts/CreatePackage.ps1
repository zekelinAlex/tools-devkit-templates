$name = Split-Path -Leaf (Get-Location)
$csproj = "$name.csproj"

pac package init --package-name $name 

$content = Get-Content $csproj -Raw
$content = $content -replace '<PackageReference Include="Microsoft\.PowerApps\.MSBuild\.PDPackage" Version="1.*">', ''
$content = $content -replace '      <PrivateAssets>all</PrivateAssets>', ''
$content = $content -replace '      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>', ''
$content = $content -replace '    </PackageReference>', ''
$content = $content -replace '    </PackageReference>', ''


$content = $content -replace '<Copyright>Copyright © 2025</Copyright>', '<Copyright>Copyright © 2025</Copyright>     <ProjectType>PdPackage</ProjectType>'

Set-Content -Path $csproj -Value $content -NoNewline