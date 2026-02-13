$jsonString = 'customcontrolparametersexample'

$outputDir = ".template.temp"
$outputPath = "$outputDir\customcontrolparameters.xml"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($jsonString) -or $jsonString -eq '[]') {
    $xml = '<?xml version="1.0" encoding="utf-8"?>' + [Environment]::NewLine + '<parameters />'
    Set-Content -Path $outputPath -Value $xml -Encoding UTF8
    exit 0
}

try {
    $parameters = $jsonString | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse CustomControlParameters JSON: $_"
    Write-Error "Expected format: [{`"name`": `"paramName`", `"type`": `"Whole.None`", `"value`": `"fieldvalue`"}]"
    exit 1
}

$xmlDoc = New-Object System.Xml.XmlDocument
$xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "utf-8", $null)
$xmlDoc.AppendChild($xmlDeclaration) | Out-Null

$parametersElement = $xmlDoc.CreateElement("parameters")
$xmlDoc.AppendChild($parametersElement) | Out-Null

foreach ($param in $parameters) {
    if (-not $param.name) {
        Write-Warning "Skipping parameter without 'name' property"
        continue
    }
    if (-not $param.type) {
        Write-Warning "Skipping parameter '$($param.name)' without 'type' property"
        continue
    }

    $element = $xmlDoc.CreateElement($param.name)
    $element.SetAttribute("type", $param.type)

    if ($param.value) {
        $element.InnerText = $param.value
    }

    $parametersElement.AppendChild($element) | Out-Null
}

$xmlDoc.Save($outputPath)

Write-Host "Generated customcontrolparameters.xml with $($parameters.Count) parameter(s)"
