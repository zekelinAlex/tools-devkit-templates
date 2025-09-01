$removeDefaultTab = "removefefaulttabchoice"

$mainFormId = "formguididexample"
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

if ($removeDefaultTab -eq "True") {
    [xml]$entityXml = Get-Content -Path $entityXmlPath -Raw
    
    $generalTab = $entityXml.SelectSingleNode('//tab[@name="generaltab"]')
    
    if ($generalTab) {
        $generalTab.ParentNode.RemoveChild($generalTab) | Out-Null
        
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Indent = $true
        $settings.NewLineHandling = [System.Xml.NewLineHandling]::None
        $settings.OmitXmlDeclaration = $false
        
        $writer = [System.Xml.XmlWriter]::Create($entityXmlPath, $settings)
        $entityXml.Save($writer)
        $writer.Close()
        
        Write-Host "Default tab 'generaltab' has been removed from $entityXmlPath"
    } else {
        Write-Warning "Tab with name='generaltab' not found in $entityXmlPath"
    }
}