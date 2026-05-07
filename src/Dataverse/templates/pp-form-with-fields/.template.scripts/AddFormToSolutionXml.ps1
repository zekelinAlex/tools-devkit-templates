param(
    [Parameter(Mandatory=$true)]
    [string]$formId,
    [Parameter(Mandatory=$false)]
    [string]$formType = "main"
)

$ErrorActionPreference = 'Stop'

$solutionPath = Resolve-Path -Path '__solution-declarations-root__/Other/Solution.xml'

[XML]$file = Get-Content -Path $solutionPath -Raw
$rootComponents = $file.SelectSingleNode("//RootComponents")
if (-not $rootComponents) {
    Write-Warning "<RootComponents> not found in Solution.xml; skipping form registration."
    return
}

$newComponent = $file.CreateElement("RootComponent")
$newComponent.SetAttribute("type", '60')
$newComponent.SetAttribute("id", $formId)
# `behavior` attribute is only set for non-dialog forms; dialogs go without it.
if ($formType -ne "dialog") {
    $newComponent.SetAttribute("behavior", '0')
}

$null = $rootComponents.AppendChild($newComponent)

$file.Save($solutionPath)
