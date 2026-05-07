$groupPath  = (Resolve-Path '.template.temp/group.xml').Path

[XML]$File = Get-Content -Path $groupPath -Raw

$XmlText = $File.OuterXml
$modifiedXmlText = $XmlText -replace [Regex]::Escape("__talxis-group-id__"), ([guid]::NewGuid().ToString() -split '-')[0]

[XML]$File = $ModifiedXmlText

$File.Save($groupPath)