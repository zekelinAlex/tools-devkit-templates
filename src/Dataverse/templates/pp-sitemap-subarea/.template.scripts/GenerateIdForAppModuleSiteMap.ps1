$subareaPath  = (Resolve-Path '.template.temp/subarea.xml').Path

[XML]$File = Get-Content -Path $subareaPath -Raw

$XmlText = $File.OuterXml
$modifiedXmlText = $XmlText -replace [Regex]::Escape("__talxis-subarea-id__"), ([guid]::NewGuid().ToString() -split '-')[0]

[XML]$File = $ModifiedXmlText

$File.Save($subareaPath)