$filePath = "webresourcefilepathexample"
$destinationFolder = "SolutionDeclarationsRoot\WebResources"
$fileName = [System.IO.Path]::GetFileName($filePath)
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ppRootDir = Split-Path -Parent $scriptDir
$jsBuildTargetPath = Join-Path $ppRootDir ".template.temp\JsBuildTarget.xml"

if (Test-Path -LiteralPath $jsBuildTargetPath) {
    $content = Get-Content -LiteralPath $jsBuildTargetPath -Raw
    $updated = $content -replace 'fileexamplename', $baseName
    $effective = if ($updated) { $updated } else { $content }

    try {
        [xml]$buildDoc = $effective
    } catch {
        return
    }

    $buildRoot = $buildDoc.SelectSingleNode('/BuildTarget')
    if ($null -ne $buildRoot) {
        $ProjectPath = "."
        $projectFiles = Get-ChildItem -Path $ProjectPath -Filter "*.cdsproj" -Recurse | Select-Object -First 1
        if (-not $projectFiles) {
            $projectFiles = Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -Recurse | Select-Object -First 1
        }
        if (-not $projectFiles) {
            Write-Host "No .cdsproj or .csproj files found in the current directory or subdirectories"
            return
        }

        $projectFile = $projectFiles[0]

        try {
            [xml]$xml = Get-Content $projectFile.FullName -Raw
        } catch {
            return
        }

        $existingTargets = $xml.SelectSingleNode("//Target[@Name='BuildTypeScript']")
        if ($existingTargets) {
            Write-Host "Targets already exist in $($projectFile.Name)"
            return
        }

        foreach ($node in $buildRoot.ChildNodes) {
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $importedNode = $xml.ImportNode($node, $true)
                $xml.Project.AppendChild($importedNode) | Out-Null
            }
        }

        $xml.Save($projectFile.FullName)

        $textContent = Get-Content -Path $projectFile.FullName -Raw
        $updatedTextContent = $textContent -replace 'xmlns=""',''
        if ($updatedTextContent -ne $textContent) {
            Set-Content -Path $projectFile.FullName -Value $updatedTextContent -Encoding utf8
        }
    }
} 

