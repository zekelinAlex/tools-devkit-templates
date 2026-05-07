$tabXmlPath = './.template.temp/section.xml'
$tabId = "__section-id__"
$name = "__section-name__"

if ($tabId -eq "unknown") {
    $tabId = [System.Guid]::NewGuid().ToString()
}

$processedName = $name.ToLower() -replace '[^a-z0-9]', ''

$tabXmlContent = Get-Content -Path $tabXmlPath -Raw
$tabXmlContent = $tabXmlContent -replace '__section-id__', $tabId
$tabXmlContent = $tabXmlContent -replace 'examplesectionname', $processedName
Set-Content -Path $tabXmlPath -Value $tabXmlContent