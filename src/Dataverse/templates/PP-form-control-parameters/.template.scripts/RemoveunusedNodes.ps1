$XmlFilePath = ".template.temp\parameters.xml"

[xml]$xmlDoc = Get-Content $XmlFilePath -Encoding UTF8
    
$nodesToRemove = $xmlDoc.SelectNodes("//*[text()='defaultеtemplateexample']")
    
for ($i = $nodesToRemove.Count - 1; $i -ge 0; $i--) {
    $node = $nodesToRemove[$i]
    
    $node.ParentNode.RemoveChild($node) | Out-Null
}
    
$xmlDoc.Save($XmlFilePath)
    