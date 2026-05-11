$dashboardIdParam = "__dashboard-id-default-value__"

if ([string]::IsNullOrWhiteSpace($dashboardIdParam) -or $dashboardIdParam -eq "unknown") {
    $dashboardId = [System.Guid]::NewGuid().ToString()
} else {
    $dashboardId = $dashboardIdParam.Trim('{', '}')
}

$dashboardIdBraced = "{$dashboardId}"

$skeletonPath = (Resolve-Path './__solution-declarations-root__/Dashboards/__dashboard-id__.xml').Path

& "./.template.scripts/ReplacePlaceholder.ps1" `
    -Path $skeletonPath `
    -Placeholder "__dashboard-id__" `
    -Replacement $dashboardIdBraced

$dashboardDir = Split-Path $skeletonPath -Parent
$newFilePath  = Join-Path $dashboardDir "$dashboardIdBraced.xml"

$solutionPath = './__solution-declarations-root__/Other/Solution.xml'
if (Test-Path $solutionPath) {
    & "./.template.scripts/AddDashboardToSolutionXml.ps1" -formId $dashboardIdBraced
}
