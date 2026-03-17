$entityXmlPath = .\.template.scripts\LocateForm.ps1
$controlDescriptionId = "controlDescriptionIdexample"
$customControlFormFactor="customcontrolformfactorexample"
$customControlName="examplepublisherprefix_customcontrolnameexample"
$fieldLogicalName="fieldlogicalnameexample"

[xml]$entityXml = Get-Content -Path $entityXmlPath -Raw

$parameterPath = (Resolve-Path './.template.temp/customcontrolparameters.xml').Path

$formNode = $entityXml.SelectSingleNode("//form")
if (-not $formNode) {
    Write-Error "Form node not found"
    exit 1
}

# Find the control by datafieldname and add uniqueid attribute
$controlNode = $formNode.SelectSingleNode(".//control[@datafieldname='$fieldLogicalName']")
if ($controlNode) {
    if (-not $controlNode.GetAttribute("uniqueid")) {
        $controlNode.SetAttribute("uniqueid", "{$controlDescriptionId}")
        Write-Host "Added uniqueid='{$controlDescriptionId}' to control '$fieldLogicalName'"
    }
} else {
    Write-Warning "Control with datafieldname='$fieldLogicalName' not found in form"
}

# Create controlDescriptions structure
$controlDescriptionsNode = $formNode.SelectSingleNode("./controlDescriptions")
if (-not $controlDescriptionsNode) {
    $controlDescriptionsNode = $entityXml.CreateElement("controlDescriptions")
    $formNode.AppendChild($controlDescriptionsNode) | Out-Null
}

$controlDescriptionNode = $controlDescriptionsNode.SelectSingleNode("./controlDescription[@forControl='{$controlDescriptionId}']")
if (-not $controlDescriptionNode) {
    $controlDescriptionNode = $entityXml.CreateElement("controlDescription")
    $controlDescriptionNode.SetAttribute("forControl", "{$controlDescriptionId}")
    $controlDescriptionsNode.AppendChild($controlDescriptionNode) | Out-Null
}

# Create default customControl (without formFactor) if it doesn't exist yet
$defaultCustomControlNode = $controlDescriptionNode.SelectSingleNode("./customControl[not(@formFactor)]")
if (-not $defaultCustomControlNode) {
    $defaultCustomControlNode = $entityXml.CreateElement("customControl")
    $defaultCustomControlNode.SetAttribute("id", "{$([guid]::NewGuid().ToString('d'))}")
    $controlDescriptionNode.AppendChild($defaultCustomControlNode) | Out-Null

    $defaultParametersNode = $entityXml.CreateElement("parameters")
    $defaultCustomControlNode.AppendChild($defaultParametersNode) | Out-Null

    $datafieldnameNode = $entityXml.CreateElement("datafieldname")
    $datafieldnameNode.InnerText = $fieldLogicalName
    $defaultParametersNode.AppendChild($datafieldnameNode) | Out-Null

    Write-Host "Added default customControl with datafieldname='$fieldLogicalName'"
}

# Create formFactor-specific customControl
$customControlNode = $controlDescriptionNode.SelectSingleNode("./customControl[@formFactor='$customControlFormFactor' and @name='$customControlName']")
if (-not $customControlNode) {
    $customControlNode = $entityXml.CreateElement("customControl")
    $customControlNode.SetAttribute("formFactor", $customControlFormFactor)
    $customControlNode.SetAttribute("name", $customControlName)
    $controlDescriptionNode.AppendChild($customControlNode) | Out-Null

    $parametersNode = $entityXml.CreateElement("parameters")
    $customControlNode.AppendChild($parametersNode) | Out-Null
} else {
    $parametersNode = $customControlNode.SelectSingleNode("./parameters")
    if (-not $parametersNode) {
        $parametersNode = $entityXml.CreateElement("parameters")
        $customControlNode.AppendChild($parametersNode) | Out-Null
    }
}

if (Test-Path $parameterPath) {
    [xml]$parameterXml = Get-Content -Path $parameterPath -Raw
    foreach ($childNode in $parameterXml.DocumentElement.ChildNodes) {
        $importedNode = $entityXml.ImportNode($childNode, $true)
        $parametersNode.AppendChild($importedNode) | Out-Null
    }
}

$entityXml.Save($entityXmlPath)
