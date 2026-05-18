$chartIdParam = "__chart-id-default-value__"

if ([string]::IsNullOrWhiteSpace($chartIdParam) -or $chartIdParam -eq "unknown") {
    $chartId = [System.Guid]::NewGuid().ToString()
} else {
    $chartId = $chartIdParam.Trim('{', '}')
}

# Production charts use uppercase-braced GUIDs in both the filename and the savedqueryvisualizationid element.
$chartIdBraced = "{" + $chartId.ToUpper() + "}"

$skeletonPath = (Resolve-Path './__solution-declarations-root__/Entities/__entity-schema-name__/Visualizations/__chart-id__.xml').Path

& "./.template.scripts/ReplacePlaceholder.ps1" `
    -Path $skeletonPath `
    -Placeholder "__chart-id__" `
    -Replacement $chartIdBraced
