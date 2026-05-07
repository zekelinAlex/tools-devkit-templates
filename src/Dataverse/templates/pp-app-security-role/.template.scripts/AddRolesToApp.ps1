$entityXmlPath = (Resolve-Path '__solution-declarations-root__/AppModules/__app-logical-name__/AppModule.xml').Path
$privilegesPath = (Resolve-Path '.template.scripts/appaccess.xml').Path


[xml]$entityXml = Get-Content -Path $entityXmlPath -Raw

$rootNode = $entityXml.SelectSingleNode('//AppModule')
if (-not $rootNode) {
    Write-Error "AppModule root not found"
    exit 1
}

$privilegesRaw = Get-Content -Path $privilegesPath -Raw
$wrapped = "<AppModuleRoleMaps>$privilegesRaw</AppModuleRoleMaps>"
[xml]$rolesXml = $wrapped


$newRolesNode = $rolesXml.DocumentElement
if (-not $newRolesNode -or $newRolesNode.LocalName -ne 'AppModuleRoleMaps') {
    Write-Error "Failed to build <AppModuleRoleMaps> from $privilegesPath"
    exit 1
}

$importedNode = $entityXml.ImportNode($newRolesNode, $true)
if (-not $importedNode) {
    Write-Error "ImportNode returned null for <AppModuleRoleMaps>"
    exit 1
}

# Now it's safe to drop the old <AppModuleRoleMaps>, if any.
$existingRolesNode = $rootNode.SelectSingleNode('AppModuleRoleMaps')
if ($existingRolesNode) {
    $rootNode.RemoveChild($existingRolesNode) | Out-Null
}

$rootNode.AppendChild($importedNode) | Out-Null

$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.OmitXmlDeclaration = $false
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)

$writer = [System.Xml.XmlWriter]::Create($entityXmlPath, $settings)
$entityXml.Save($writer)
$writer.Close()
