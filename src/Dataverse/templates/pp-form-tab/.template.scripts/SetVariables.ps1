$tabXmlPath = './.template.temp/tab.xml'
$tabId = "__tab-id__"
$name = "__display-name__"

if ($tabId -eq "unknownTabId") {
    $tabId = [System.Guid]::NewGuid().ToString()
}

$processedName = $name.ToLower() -replace '[^a-z0-9]', ''

$tabXmlContent = Get-Content -Path $tabXmlPath -Raw
$tabXmlContent = $tabXmlContent -replace '__tab-id__', $tabId
$tabXmlContent = $tabXmlContent -replace '__talxis-tab-name__', $processedName
Set-Content -Path $tabXmlPath -Value $tabXmlContent