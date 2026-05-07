# Resolve the relative path to an absolute path (to support other OSes)
# Try both naming conventions (with and without _managed suffix)
$candidatePath = '__solution-declarations-root__/AppModules/__app-name__/AppModule.xml'
$candidatePathManaged = '__solution-declarations-root__/AppModules/__app-name__/AppModule_managed.xml'
if (Test-Path $candidatePath) {
    $solutionPath = Resolve-Path -Path $candidatePath
} elseif (Test-Path $candidatePathManaged) {
    $solutionPath = Resolve-Path -Path $candidatePathManaged
} else {
    Write-Warning "No AppModule XML found — skipping component registration"
    exit 0
}

# Load the XML file
[XML]$File = Get-Content -Path $solutionPath -Raw
$rootComponents = $File.SelectSingleNode("//AppModuleComponents")

$newComponent = $File.CreateElement("AppModuleComponent")
$newComponent.SetAttribute("type", '__entity-type-id__')

if ( "__entity-type-id__" -eq "1") {
    $newComponent.SetAttribute("schemaName", '__entity-logical-name__')
}
else {
    $newComponent.SetAttribute("id", '{__component-id__}')
}

# Append the new component to the root components without writing output to console
$null = $rootComponents.AppendChild($newComponent)

# Save the updated XML back to the file
$File.Save($solutionPath)