$ProjectPath = "."

# Find .cdsproj file first, then .csproj as fallback
$projectFiles = Get-ChildItem -Path $ProjectPath -Filter "*.cdsproj" -Recurse | Select-Object -First 1
if (-not $projectFiles) {
    $projectFiles = Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -Recurse | Select-Object -First 1
}

if (-not $projectFiles) {
    Write-Error "No .cdsproj or .csproj files found in the current directory or subdirectories"
    exit 1
}

$projectFile = $projectFiles[0]

# Load project file as XML
[xml]$xml = Get-Content $projectFile.FullName -Raw

# Load targets.xml file
$targetsPath = ".template.temp/targets.xml"
if (-not (Test-Path $targetsPath)) {
    Write-Error "Targets file not found: $targetsPath"
    exit 1
}

[xml]$targetsXml = Get-Content $targetsPath -Raw

# Check if targets already exist in the project
$existingTargets = $xml.SelectSingleNode("//Target[@Name='CopyReferencedAssemblies']")

if ($existingTargets) {
    Write-Host "Targets already exist in $($projectFile.Name)"
    exit 0
}

# Import all Target elements from targets.xml into the project
foreach ($target in $targetsXml.Project.Target) {
    $importedTarget = $xml.ImportNode($target, $true)
    $xml.Project.AppendChild($importedTarget) | Out-Null
}

# Save the updated project file
$xml.Save($projectFile.FullName)

# Re-open the project file as plain text and remove empty xmlns attributes
$textContent = Get-Content -Path $projectFile.FullName -Raw
$updatedTextContent = $textContent -replace 'xmlns=""',''

if ($updatedTextContent -ne $textContent) {
    Set-Content -Path $projectFile.FullName -Value $updatedTextContent -Encoding utf8
}

