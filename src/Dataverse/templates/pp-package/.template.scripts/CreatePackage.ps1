$name = Split-Path -Leaf (Get-Location)
$csproj = "$name.csproj"
$csprojPath = "$name.csproj"

pac package init --package-name $name 

$content = Get-Content $csproj -Raw
$content = $content -replace '<PackageReference Include="Microsoft\.PowerApps\.MSBuild\.PDPackage" Version="1.*">', ''
$content = $content -replace '      <PrivateAssets>all</PrivateAssets>', ''
$content = $content -replace '      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>', ''
$content = $content -replace '    </PackageReference>', ''
$content = $content -replace '    </PackageReference>', ''

Set-Content -Path $csproj -Value $content -NoNewline

$csprojText = Get-Content $csproj -Raw
$csprojText = $csprojText -replace '<Project Sdk="Microsoft.NET.Sdk">', '<Project Sdk="TALXIS.DevKit.Build.Sdk/0.0.0.9">'
Set-Content -Path $csproj -Value $csprojText

[xml]$csproj = $csprojText
$namespaceUri = $csproj.DocumentElement.NamespaceURI

$firstPropertyGroup = $csproj.Project.PropertyGroup | Select-Object -First 1
if (-not $firstPropertyGroup) {
    $firstPropertyGroup = $csproj.CreateElement("PropertyGroup", $namespaceUri)
    $csproj.Project.PrependChild($firstPropertyGroup) | Out-Null
}
$projectTypeElement = $firstPropertyGroup.ProjectType
if (-not $projectTypeElement) {
    $projectTypeElement = $csproj.CreateElement("ProjectType", $namespaceUri)
    $projectTypeElement.InnerText = "PDPackage"
    $firstPropertyGroup.AppendChild($projectTypeElement) | Out-Null
} else {
    $projectTypeElement.InnerText = "PDPackage"
}

$csproj.Save($csprojPath)