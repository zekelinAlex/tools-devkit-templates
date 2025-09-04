$tabId = "tabexampleid"
$tabNumber = "tabnumberexample"
$columnNumber = "columnnumberexample"
$entityXmlPath = .\.template.scripts\LocateForm.ps1

$sectionPath = (Resolve-Path './.template.temp/section.xml').Path

[xml]$entityXml = Get-Content -Path $entityXmlPath -Raw

$targetTab = $null

if ($tabId -ne "unknown" -and $tabNumber -ne "unknown") {
    $targetTab = $entityXml.SelectSingleNode("//tab[@id='$tabId']")
    if (-not $targetTab) {
        $tabs = $entityXml.SelectNodes("//tab")
        if ($tabs.Count -ge [int]$tabNumber) {
            $targetTab = $tabs[[int]$tabNumber - 1]
        }
    }
} elseif ($tabId -ne "unknown") {
    $targetTab = $entityXml.SelectSingleNode("//tab[@id='$tabId']")
} elseif ($tabNumber -ne "unknown") {
    $tabs = $entityXml.SelectNodes("//tab")
    if ($tabs.Count -ge [int]$tabNumber) {
        $targetTab = $tabs[[int]$tabNumber - 1]
    }
} else {
    $tabs = $entityXml.SelectNodes("//tab")
    if ($tabs.Count -gt 0) {
        $targetTab = $tabs[$tabs.Count - 1]
    }
}

if (-not $targetTab) {
    Write-Error "Target tab not found"
    exit 1
}

# Find the target column within the target tab
$targetColumn = $null

if ($columnNumber -ne "unknown") {
    # Find column by number
    $columns = $targetTab.SelectNodes('./columns/column')
    if ($columns.Count -ge [int]$columnNumber) {
        $targetColumn = $columns[[int]$columnNumber - 1]
    }
} else {
    # Use the last column
    $columns = $targetTab.SelectNodes('./columns/column')
    if ($columns.Count -gt 0) {
        $targetColumn = $columns[$columns.Count - 1]
    }
}

if (-not $targetColumn) {
    Write-Error "Target column not found in the selected tab"
    exit 1
}

# Find or create sections node within the target column
$sectionsNode = $targetColumn.SelectSingleNode('./sections')
if (-not $sectionsNode) {
    # Create sections node if it doesn't exist
    $sectionsNode = $entityXml.CreateElement("sections")
    $targetColumn.AppendChild($sectionsNode) | Out-Null
}

$sectionRaw = Get-Content -Path $sectionPath -Raw
$wrapped = "<sections>$sectionRaw</sections>"
[xml]$newsectionsXml = $wrapped

foreach ($section in $newsectionsXml.sections.ChildNodes) {
    $imported = $entityXml.ImportNode($section, $true)
    $sectionsNode.AppendChild($imported) | Out-Null
}

$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.NewLineHandling = [System.Xml.NewLineHandling]::None
$settings.OmitXmlDeclaration = $false

$writer = [System.Xml.XmlWriter]::Create($entityXmlPath, $settings)
$entityXml.Save($writer)
$writer.Close()