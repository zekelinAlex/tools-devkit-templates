$ProjectPath = "."

$projectFiles = Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -Recurse | Select-Object -First 1
if (-not $projectFiles) {
    $projectFiles = Get-ChildItem -Path $ProjectPath -Filter "*.cdsproj" -Recurse | Select-Object -First 1
}

if (-not $projectFiles) {
    Write-Error "No .csproj or .cdsproj files found in the current directory or subdirectories"
    exit 1
}

$projectFile = $projectFiles[0]

[xml]$xml = Get-Content $projectFile.FullName -Raw

$existingSolutionRef = $xml.SelectSingleNode("//PackageReference[@Include='TALXIS.SDK.BuildTargets.CDS.Solution']")
$existingTypeScriptRef = $xml.SelectSingleNode("//PackageReference[@Include='TALXIS.SDK.BuildTargets.CDS.TypeScriptCommon']")

if ($existingSolutionRef -and $existingTypeScriptRef) {
    exit 0
}

$itemGroup = $xml.SelectSingleNode("//ItemGroup[PackageReference]")
if (-not $itemGroup) {
    $itemGroup = $xml.CreateElement("ItemGroup", $xml.Project.NamespaceURI)
    
    $xml.Project.AppendChild($itemGroup) | Out-Null
}

if (-not $existingSolutionRef) {
    $solutionRef = $xml.CreateElement("PackageReference", $xml.Project.NamespaceURI)
    $solutionRef.SetAttribute("Include", "TALXIS.SDK.BuildTargets.CDS.Solution")
    $solutionRef.SetAttribute("Version", "2.0.*")

    $itemGroup.AppendChild($solutionRef) | Out-Null
}

if (-not $existingTypeScriptRef) {
    $typeScriptRef = $xml.CreateElement("PackageReference", $xml.Project.NamespaceURI)
    $typeScriptRef.SetAttribute("Include", "TALXIS.SDK.BuildTargets.CDS.TypeScriptCommon")
    $typeScriptRef.SetAttribute("Version", "2.1.*")

    $itemGroup.AppendChild($typeScriptRef) | Out-Null
}

$xml.Save($projectFile.FullName)

