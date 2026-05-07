$fieldsRaw = "__fields__"
$formType  = "__form-type__"

if ($formType -eq "dialog") {
    $formPath = (Resolve-Path './__solution-declarations-root__/Dialogs/dialogform.xml').Path
} else {
    $formPath = (Resolve-Path './__solution-declarations-root__/Entities/__entity-logical-name__/FormXml/main/mainform.xml').Path
}

[xml]$xml = Get-Content -Path $formPath -Raw

$rowsNode = $xml.SelectSingleNode("//tabs/tab/columns/column/sections/section/rows")
if (-not $rowsNode) {
    Write-Error "Could not locate <section>/<rows> in form skeleton at $formPath."
    exit 1
}

# classid lookup — same table used by pp-form-control. First-version subset:
# only types that need no extra <parameters>. Lookup/SubGrid/Button to follow.
$classIds = @{
    "Text"          = "{4273EDBD-AC1D-40d3-9FB2-095C621B552D}"
    "MultilineText" = "{E0DECE4B-6FC8-4a8f-A065-082708572369}"
    "WholeNumber"   = "{C3EFE0C3-0EC6-42be-8349-CBD9079DFD8E}"
    "Decimal"       = "{C3EFE0C3-0EC6-42be-8349-CBD9079DFD8E}"
    "Float"         = "{0D2C745A-E5A8-4c8f-BA63-C6D3BB604660}"
    "Currency"      = "{533B9E00-756B-4312-95A0-DC888637AC78}"
    "DateTime"      = "{5B773807-9FB2-42db-97C3-7A91EFF8ADFF}"
    "OptionSet"     = "{3EF39988-22BB-4F0B-BBBE-64B5A3748AEE}"
}

if ([string]::IsNullOrWhiteSpace($fieldsRaw)) {
    Write-Warning "No fields supplied; form will be created without controls."
    $xml.Save($formPath)
    exit 0
}

function Get-DefaultDisplayName {
    param([string]$logicalName)
    $stripped = $logicalName -replace '^[a-z0-9]+_', ''
    if ([string]::IsNullOrEmpty($stripped)) { return $logicalName }
    return ($stripped.Substring(0, 1).ToUpper() + $stripped.Substring(1))
}

$fields = $fieldsRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$added = 0
$skipped = @()

foreach ($field in $fields) {
    $parts = $field -split ':' | ForEach-Object { $_.Trim() }
    if ($parts.Count -lt 2) {
        $skipped += "$field (need at least 'name:type')"
        continue
    }

    $name = $parts[0]
    $type = $parts[1]
    $displayName = if ($parts.Count -ge 3 -and -not [string]::IsNullOrWhiteSpace($parts[2])) {
        $parts[2]
    } else {
        Get-DefaultDisplayName -logicalName $name
    }

    if (-not $classIds.ContainsKey($type)) {
        $skipped += "$field (unknown ControlType '$type')"
        continue
    }
    $classId = $classIds[$type]

    $cellId  = "{" + ([guid]::NewGuid().ToString().ToUpper()) + "}"
    $labelId = "{" + ([guid]::NewGuid().ToString().ToUpper()) + "}"

    # Build the row via DOM (safer than string interpolation for arbitrary displayName).
    $rowNode = $xml.CreateElement('row')

    $cellNode = $xml.CreateElement('cell')
    $cellNode.SetAttribute('id', $cellId)
    $cellNode.SetAttribute('labelid', $labelId)

    $labelsNode = $xml.CreateElement('labels')
    $labelNode  = $xml.CreateElement('label')
    $labelNode.SetAttribute('description', $displayName)
    $labelNode.SetAttribute('languagecode', '1033')
    $labelsNode.AppendChild($labelNode) | Out-Null

    $controlNode = $xml.CreateElement('control')
    $controlNode.SetAttribute('id', $name)
    $controlNode.SetAttribute('classid', $classId)
    

    <!--#if (FormType != "dialog") -->
    $controlNode.SetAttribute('datafieldname', $name)
    $controlNode.SetAttribute('disabled', 'false')
    <!--#else -->
    $controlNode.SetAttribute('isunbound', 'true')
    $controlNode.SetAttribute('isrequired', 'false')
    $controlNode.SetAttribute('uniqueid', "`{$([guid]::NewGuid())`}")
    <!--#endif -->


    $cellNode.AppendChild($labelsNode) | Out-Null
    $cellNode.AppendChild($controlNode) | Out-Null
    $rowNode.AppendChild($cellNode) | Out-Null

    $rowsNode.AppendChild($rowNode) | Out-Null
    $added++
}

$xml.Save($formPath)

Write-Host "[pp-form-with-fields] Added $added field(s) to form."
foreach ($s in $skipped) {
    Write-Warning "[pp-form-with-fields] Skipped: $s"
}
