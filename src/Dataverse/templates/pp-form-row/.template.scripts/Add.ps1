$mainFormId = "formguididexample"
$tabId = "tabexampleid"
$tabNumber = "tabnumberexample"
$columnNumber = "columnnumberexample"
$sectionId = "sectionidexample"
$sectionNumber = "sectionnumberexample"
$entityXmlPath

if ($mainFormId -eq "unknownFormId") {
    $formDirectory = './SolutionDeclarationsRoot/Entities/exampleentityname/FormXml/formtypeexample/'

    $latestForm = Get-ChildItem -Path $formDirectory -Filter "*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($latestForm) {
        $entityXmlPath = $latestForm.FullName
    } else {
        Write-Error "No XML forms found in directory: $formDirectory"

        exit 1
    }
} else {
    $entityXmlPath=(Resolve-Path './SolutionDeclarationsRoot/Entities/exampleentityname/FormXml/formtypeexample/{$mainFormId}.xml').Path
}

$rowPath = (Resolve-Path './.template.temp/row.xml').Path

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

# Find the target section within the target column
$targetSection = $null

if ($sectionId -ne "unknown" -and $sectionNumber -ne "unknown") {
    # Try to find section by ID first, then by number
    $targetSection = $targetColumn.SelectSingleNode("./sections/section[@id='$sectionId']")
    if (-not $targetSection) {
        $sections = $targetColumn.SelectNodes('./sections/section')
        if ($sections.Count -ge [int]$sectionNumber) {
            $targetSection = $sections[[int]$sectionNumber - 1]
        }
    }
} elseif ($sectionId -ne "unknown") {
    # Find section by ID only
    $targetSection = $targetColumn.SelectSingleNode("./sections/section[@id='$sectionId']")
} elseif ($sectionNumber -ne "unknown") {
    # Find section by number only
    $sections = $targetColumn.SelectNodes('./sections/section')
    if ($sections.Count -ge [int]$sectionNumber) {
        $targetSection = $sections[[int]$sectionNumber - 1]
    }
} else {
    # Both are unknown, use the last section
    $sections = $targetColumn.SelectNodes('./sections/section')
    if ($sections.Count -gt 0) {
        $targetSection = $sections[$sections.Count - 1]
    }
}

if (-not $targetSection) {
    Write-Error "Target section not found in the selected column"
    exit 1
}

# Find or create rows node within the target section
$rowsNode = $targetSection.SelectSingleNode('./rows')
if (-not $rowsNode) {
    # Create rows node if it doesn't exist
    $rowsNode = $entityXml.CreateElement("rows")
    $targetSection.AppendChild($rowsNode) | Out-Null
}

$rowRaw = Get-Content -Path $rowPath -Raw
$wrapped = "<rows>$rowRaw</rows>"
[xml]$newrowsXml = $wrapped

foreach ($row in $newrowsXml.rows.ChildNodes) {
    $imported = $entityXml.ImportNode($row, $true)
    $rowsNode.AppendChild($imported) | Out-Null
}

$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.NewLineHandling = [System.Xml.NewLineHandling]::None
$settings.OmitXmlDeclaration = $false

$writer = [System.Xml.XmlWriter]::Create($entityXmlPath, $settings)
$entityXml.Save($writer)
$writer.Close()