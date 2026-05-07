# Resolve the relative path to an absolute path (to support other OSes)
$entityXmlPath = (Resolve-Path '__solution-declarations-root__/Entities/__entity-logical-name__/Entity.xml').Path
$attributeXmlPath = (Resolve-Path '.template.temp/attribute.xml').Path

[XML]$entityXmlFile = Get-Content -Path $entityXmlPath -Raw
[XML]$attributeXmlFile = Get-Content -Path $attributeXmlPath -Raw

# Collect <attribute> nodes from the source file.
$root = $attributeXmlFile.DocumentElement
if ($root.LocalName -eq 'attribute') {
    $attributeNodes = @($root)
} else {
    $attributeNodes = @($root.SelectNodes('attribute'))
}

if ($attributeNodes.Count -eq 0) {
    Write-Error "No <attribute> elements found in $attributeXmlPath"
    exit 1
}

# Add each attribute to entity
$attributesContainer = $entityXmlFile.Entity.EntityInfo.entity.attributes
foreach ($attrNode in $attributeNodes) {
    $importedNode = $entityXmlFile.ImportNode($attrNode, $true)
    $attributesContainer.AppendChild($importedNode) | Out-Null
}

# Configure XmlWriter settings to avoid unwanted whitespace
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.NewLineHandling = [System.Xml.NewLineHandling]::None
$settings.OmitXmlDeclaration = $false

# Save
$writer = [System.Xml.XmlWriter]::Create($entityXmlPath, $settings)
$entityXmlFile.Save($writer)

$writer.Close()
