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

$existingCoreAssemblies = $xml.SelectSingleNode("//PackageReference[@Include='Microsoft.CrmSdk.CoreAssemblies']")
$existingWorkflow = $xml.SelectSingleNode("//PackageReference[@Include='Microsoft.CrmSdk.Workflow']")
$existingNewtonsoftJson = $xml.SelectSingleNode("//PackageReference[@Include='Newtonsoft.Json']")

# Check if SolutionDir already exists
$existingSolutionDir = $xml.SelectSingleNode("//SolutionDir")

if ($existingSolutionRef -and $existingTypeScriptRef -and $existingSolutionDir) {
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

if (-not $existingCoreAssemblies) {
    $coreAssembliesRef = $xml.CreateElement("PackageReference", $xml.Project.NamespaceURI)
    $coreAssembliesRef.SetAttribute("Include", "Microsoft.CrmSdk.CoreAssemblies")
    $coreAssembliesRef.SetAttribute("Version", "9.0.*")

    $itemGroup.AppendChild($coreAssembliesRef) | Out-Null
}

if (-not $existingWorkflow) {
    $workflowRef = $xml.CreateElement("PackageReference", $xml.Project.NamespaceURI)
    $workflowRef.SetAttribute("Include", "Microsoft.CrmSdk.Workflow")
    $workflowRef.SetAttribute("Version", "9.0.*")
    
    $itemGroup.AppendChild($workflowRef) | Out-Null
}

if (-not $existingNewtonsoftJson) {
    $newtonsoftJsonRef = $xml.CreateElement("PackageReference", $xml.Project.NamespaceURI)
    $newtonsoftJsonRef.SetAttribute("Include", "Newtonsoft.Json")
    $newtonsoftJsonRef.SetAttribute("Version", "13.0.*")
    

    $itemGroup.AppendChild($newtonsoftJsonRef) | Out-Null
}

# Add SolutionDir to the second PropertyGroup
if (-not $existingSolutionDir) {
    # Get all PropertyGroup elements
    $propertyGroups = $xml.SelectNodes("//PropertyGroup")
    
    if ($propertyGroups.Count -ge 2) {
        # Use the second PropertyGroup (index 1)
        $secondPropertyGroup = $propertyGroups[1]
    } else {
        # If there's only one PropertyGroup, create a second one
        $secondPropertyGroup = $xml.CreateElement("PropertyGroup", $xml.Project.NamespaceURI)
        $xml.Project.AppendChild($secondPropertyGroup) | Out-Null
    }
    
    # Create and add SolutionDir element
    $solutionDirElement = $xml.CreateElement("SolutionDir", $xml.Project.NamespaceURI)
    $solutionDirElement.InnerText = '$(MSBuildThisFileDirectory)..\..\'
    $secondPropertyGroup.AppendChild($solutionDirElement) | Out-Null
}

$xml.Save($projectFile.FullName)

