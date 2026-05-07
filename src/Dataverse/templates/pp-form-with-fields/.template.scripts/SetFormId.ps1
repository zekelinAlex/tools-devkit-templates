# Sets the form id in the generated form XML, renames the file from the
# placeholder name to "{<formId>}.xml", and (if a Solution.xml is present)
# registers the form as a RootComponent in the solution.
#
# For dialog forms, additionally sets <UniqueName>. We fold that into this
# script (rather than a separate post-action) because we need the runtime-
# generated GUID and passing it between scripts is awkward.
#
# Element naming differs between form types:
#   main   -> <formid> (lowercase) at //formid
#   dialog -> <FormId> (TitleCase) at //FormId

$ErrorActionPreference = 'Stop'

# Replaced by template engine.
$formId            = "__form-id__"
$formType          = "__form-type__"
$formName          = "__form-name__"
$entitySchemaName  = "__entity-logical-name__"
$dialogUniqueName  = "__dialog-unique-name__"

if ($formType -eq "dialog") {
    $formIdPath  = (Resolve-Path './__solution-declarations-root__/Dialogs/dialogform.xml').Path
    $formIdXPath = "//FormId"
} else {
    $formIdPath  = (Resolve-Path './__solution-declarations-root__/Entities/__entity-logical-name__/FormXml/main/mainform.xml').Path
    $formIdXPath = "//formid"
}

if ($formId -eq "unknown" -or [string]::IsNullOrWhiteSpace($formId)) {
    $formId = [System.Guid]::NewGuid().ToString()
}

if (-not (Test-Path $formIdPath)) {
    Write-Error "Form file not found at: $formIdPath"
    exit 1
}

$formIdBraced = "{$formId}"

$directory   = Split-Path $formIdPath -Parent
$newFileName = "$formIdBraced.xml"
$newFilePath = Join-Path $directory $newFileName

[xml]$formXml = Get-Content $formIdPath -Raw

$formIdNode = $formXml.SelectSingleNode($formIdXPath)
if ($formIdNode) {
    $formIdNode.InnerText = $formIdBraced
} else {
    Write-Warning "$formIdXPath node not found in form XML"
}

# Dialog-specific: also set <UniqueName>.
if ($formType -eq "dialog") {
    if ([string]::IsNullOrWhiteSpace($dialogUniqueName) -or $dialogUniqueName -eq "unknown") {
        $prefix = ($entitySchemaName -split '_')[0]
        $sanitized = ($formName -replace '[^\w]', '').ToLower()
        $uniqueNameFull = "${prefix}_${sanitized}dialog"
    } else {
        $uniqueNameFull = $dialogUniqueName
    }

    $uniqueNameNode = $formXml.SelectSingleNode("//UniqueName")
    if ($uniqueNameNode) {
        $uniqueNameNode.InnerText = $uniqueNameFull
        Write-Host "[pp-form-with-fields] Dialog UniqueName: $uniqueNameFull"
    } else {
        Write-Warning "<UniqueName> node not found in dialog XML"
    }
}

$formXml.Save($newFilePath)

if ($formIdPath -ne $newFilePath) {
    Remove-Item $formIdPath -Force
}

# Register the form in Solution.xml as RootComponent type=60 — only if a
# Solution.xml exists in the surrounding solution declarations root.
$solutionPath = './__solution-declarations-root__/Other/Solution.xml'
if (Test-Path $solutionPath) {
    & "./.template.scripts/AddFormToSolutionXml.ps1" -formId $formIdBraced -formType $formType
}

Write-Host ""
Write-Host "[pp-form-with-fields] FormId: $formIdBraced"
Write-Host "[pp-form-with-fields] Path:   $newFilePath"
Write-Host ""
