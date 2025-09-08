# Load option set option template
$optionSetOptionXmlPath = (Resolve-Path '.template.temp/optionsetoption.xml').Path
[xml]$optionSetOptionTemplate = Get-Content -Path $optionSetOptionXmlPath -Raw

# Generate random starting option number
$optionNumber = (Get-Random -Minimum 10000 -Maximum 99999) * 10000

# Load attribute XML file
$attributeXmlPath = ".template.temp/attribute.xml"
[xml]$attributeXml = Get-Content -Path $attributeXmlPath -Raw

# Parse options from template string
$options = "{option1},{option2},{option3}"
$options = $options.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Replace('{', '').Replace('}', '') }

Write-Host "Found options: $($options -join ', ')"

# Find the options node in attribute.xml
$optionsNode = $attributeXml.SelectSingleNode("//options")
if ($optionsNode -eq $null) {
    Write-Error "Options node not found in attribute.xml"
    exit 1
}

Write-Host "Found options node: $($optionsNode.OuterXml)"

# If options node is self-closing, we need to make it a proper container
if ($optionsNode.IsEmpty) {
    Write-Host "Options node is empty, converting to container"
    # Remove the self-closing tag and create a proper container
    $optionsetNode = $optionsNode.ParentNode
    $optionsetNode.RemoveChild($optionsNode)
    
    # Create new options node as a container
    $newOptionsNode = $attributeXml.CreateElement("options")
    $optionsetNode.AppendChild($newOptionsNode) | Out-Null
    $optionsNode = $newOptionsNode
} else {
    Write-Host "Options node is already a container"
}

# Add each option to the optionset
foreach ($option in $options) {
    Write-Host "Adding option: $option with value: $optionNumber"
    
    # Clone the template option node
    $newOptionNode = $optionSetOptionTemplate.DocumentElement.CloneNode($true)
    
    # Update option values using text replacement approach
    $optionXmlString = $newOptionNode.OuterXml
    Write-Host "Original XML: $optionXmlString"
    
    $optionXmlString = $optionXmlString -replace "exampleoptionnumber", $optionNumber
    $optionXmlString = $optionXmlString -replace "exampleoptionname", $option
    
    Write-Host "Updated XML: $optionXmlString"
    
    # Parse the updated XML string back to XML node
    [xml]$updatedOptionXml = $optionXmlString
    
    # Append the new option to the options node
    $importedNode = $attributeXml.ImportNode($updatedOptionXml.DocumentElement, $true)
    $optionsNode.AppendChild($importedNode) | Out-Null
    
    $optionNumber++
}

Write-Host "Final options node content: $($optionsNode.OuterXml)"

# Save the updated attribute XML
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.NewLineHandling = [System.Xml.NewLineHandling]::None
$settings.OmitXmlDeclaration = $false
$settings.Encoding = [System.Text.Encoding]::UTF8

$writer = [System.Xml.XmlWriter]::Create($attributeXmlPath, $settings)
$attributeXml.Save($writer)
$writer.Close()

Write-Host "File saved successfully to: $attributeXmlPath"



