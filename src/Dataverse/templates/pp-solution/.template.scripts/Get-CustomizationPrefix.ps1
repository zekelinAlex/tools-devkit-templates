$solutionPath = Resolve-Path -Path 'SolutionDeclarationsRoot/Other/Solution.xml'

[xml]$xml = Get-Content -LiteralPath $solutionPath -Raw

$node = $xml.SelectSingleNode('//CustomizationPrefix')
if (-not $node) {
    Write-Error "<CustomizationPrefix> not found in $solutionPath"
    exit 1
}

$node.InnerText
