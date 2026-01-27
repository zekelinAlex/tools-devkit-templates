# --- Input parameters ---
$signingKey = "signingkeyfilepathexample"
$outputDir = "../SolutionLogicalNameExample"
$author = "examplepublisher"
$company = "exampleсompany"

# --- 1. Initialize the plugin project ---
pac plugin init --signing-key-file-path $signingKey --outputDirectory $outputDir --author $author
cd $outputDir

# --- 2. Remove the auto-generated source file ---
Remove-Item .\Plugin1.cs -ErrorAction SilentlyContinue

# --- 3. Find the .csproj file ---
$csprojFile = Get-ChildItem -Path . -Filter *.csproj | Select-Object -First 1
if (-not $csprojFile) {
    exit 1
}

# --- 4. Generate AssemblyName by removing dots from the project name ---
$projectName = [System.IO.Path]::GetFileNameWithoutExtension($csprojFile.Name)
$newAssemblyName = $projectName -replace '\.', ''
$ProjectPath = $csprojFile.FullName

# --- 5. Update the Sdk in the .csproj text and remove unwanted elements ---
$csprojText = Get-Content $ProjectPath -Raw
$csprojText = $csprojText -replace '<Project Sdk="Microsoft\.NET\.Sdk">', '<Project Sdk="TALXIS.DevKit.Build.Sdk/0.0.0.1">'
$csprojText = $csprojText -replace '\s*<PackageReference Include="Microsoft\.PowerApps\.MSBuild\.Plugin"[^>]*/>\s*', ''
$csprojText = $csprojText -replace '\s*<Import[^>]*Project="\$\(PowerAppsTargetsPath\)\\Microsoft\.PowerApps\.VisualStudio\.Plugin\.targets"[^>]*/>\s*', ''
$csprojText = $csprojText -replace '\s*<Import[^>]*Project="\$\(PowerAppsTargetsPath\)\\Microsoft\.PowerApps\.VisualStudio\.Plugin\.props"[^>]*/>\s*', ''
$csprojText = $csprojText -replace '\s*<ProjectTypeGuids>[^<]*</ProjectTypeGuids>\s*', ''
$csprojText = $csprojText -replace '\s*<PowerAppsTargetsPath>[^<]*</PowerAppsTargetsPath>\s*', ''
Set-Content -Path $ProjectPath -Value $csprojText

# --- 6. Load .csproj as XML ---
[xml]$csproj = $csprojText
$namespaceUri = $csproj.DocumentElement.NamespaceURI

# --- 7. Find or create the first PropertyGroup ---
$firstPropertyGroup = $csproj.Project.PropertyGroup | Select-Object -First 1
if (-not $firstPropertyGroup) {
    $firstPropertyGroup = $csproj.CreateElement("PropertyGroup", $namespaceUri)
    $csproj.Project.PrependChild($firstPropertyGroup) | Out-Null
}
$projectTypeElement = $firstPropertyGroup.ProjectType
if (-not $projectTypeElement) {
    $projectTypeElement = $csproj.CreateElement("ProjectType", $namespaceUri)
    $projectTypeElement.InnerText = "Plugin"
    $firstPropertyGroup.AppendChild($projectTypeElement) | Out-Null
} else {
    $projectTypeElement.InnerText = "Plugin"
}

# --- 8. Find or create a PropertyGroup ---
$propertyGroup = $csproj.Project.PropertyGroup | Where-Object { $_.AssemblyName -or $_.TargetFramework }
if (-not $propertyGroup) {
    $propertyGroup = $csproj.CreateElement("PropertyGroup", $namespaceUri)
    $csproj.Project.AppendChild($propertyGroup) | Out-Null
}

# --- 9. Remove existing AssemblyName and PackageId ---
$csproj.Project.PropertyGroup.AssemblyName | ForEach-Object {
    $_.ParentNode.RemoveChild($_) | Out-Null
}
$csproj.Project.PropertyGroup.PackageId | ForEach-Object {
    $_.ParentNode.RemoveChild($_) | Out-Null
}
$csproj.Project.PropertyGroup.Company | ForEach-Object {
    $_.ParentNode.RemoveChild($_) | Out-Null
}

# --- 10. Add new AssemblyName and PackageId ---
$assemblyNameElement = $csproj.CreateElement("AssemblyName", $namespaceUri)
$assemblyNameElement.InnerText = $newAssemblyName
$propertyGroup.AppendChild($assemblyNameElement) | Out-Null

# --- 11. Add new PackageId ---
$packageIdElement = $csproj.CreateElement("PackageId", $namespaceUri)
$packageIdElement.InnerText = $newAssemblyName
$propertyGroup.AppendChild($packageIdElement) | Out-Null

# --- 12. Add new Company ---
$companyElement = $csproj.CreateElement("Company", $namespaceUri)
$companyElement.InnerText = $company
$propertyGroup.AppendChild($companyElement) | Out-Null

# --- 13. Save changes back to the .csproj file ---
$csproj.Save($ProjectPath)
