$dialogsRootPath = '__solution-declarations-root__/Dialogs\{__form-id__}.xml'
$formName = '__form-name__'
$EntitySchemaName = '__entity-logical-name__'

$uniqueNameFull

if ("__dialog-unique-name__" -eq "unknown") {
    $prefix = $EntitySchemaName.Split('_')[0]
    $UniqueName = $formName -replace '[^\w]', '' | ForEach-Object { $_.ToLower() }
    $uniqueNameFull =$prefix + "_" + $UniqueName + "dialog"
}
else {
    $uniqueNameFull = "__dialog-unique-name__"
}


[xml]$xmlDoc = Get-Content -Path $dialogsRootPath -Raw

$uniqueNameNode = $xmlDoc.SelectSingleNode("//UniqueName")

if ($uniqueNameNode) {
    $uniqueNameNode.InnerText = $uniqueNameFull
    
    $xmlDoc.Save($dialogsRootPath)
    Write-Host "Value updated successfully"
}
else {
    Write-Host "Node UniqueName not found"
}