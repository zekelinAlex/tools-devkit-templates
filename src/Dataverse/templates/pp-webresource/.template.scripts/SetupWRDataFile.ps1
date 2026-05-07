$filePath = "__web-resource-item-path__"
$dataXmlFilePath = "__solution-declarations-root__/WebResources\__publisher-prefix_____talxis-file-name__.data.xml"
$destinationFolder = "__solution-declarations-root__/WebResources"
#$fileDisplayName = [System.IO.Path]::GetFileName($filePath)
#$fileName = $fileDisplayName -replace '[\p{P}\p{Zs}]', ''
$fileName = [System.IO.Path]::GetFileName($filePath)
$fileDisplayName = $fileName 
$newDataXmlFilePath = "__solution-declarations-root__/WebResources\__publisher-prefix___$fileName.data.xml"

$guid = [guid]::NewGuid().ToString()
$guidUpper = $guid.ToUpper()

$content = Get-Content -Path $dataXmlFilePath -Raw

$content = $content -replace "__talxis-file-name__", $fileName
$content = $content -replace "__talxis-file-display-name__", $fileDisplayName
$content = $content -replace "__talxis-wr-id-capital__", $guidUpper
$content = $content -replace "__talxis-web-resource-id__", $guid

Remove-Item -Path $dataXmlFilePath

Set-Content -Path $newDataXmlFilePath -Value $content

$fileNewNoExtName = "__publisher-prefix___$fileName"
$destinationPath = Join-Path $destinationFolder $fileNewNoExtName

Copy-Item -Path $filePath -Destination $destinationPath

