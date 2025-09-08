$dialogsRootPath = 'SolutionDeclarationsRoot\Dialogs\{formexampleId}.xml'
$formName = 'formexamplename'
$EntitySchemaName = 'ItemFolderName'

$prefix = $EntitySchemaName.Split('_')[0]
$UniqueName = $formName -replace '[^\w]', '' | ForEach-Object { $_.ToLower() }

[xml]$xmlDoc = Get-Content -Path $dialogsRootPath -Raw

$uniqueNameNode = $xmlDoc.SelectSingleNode("//UniqueName")

if ($uniqueNameNode) {
    $uniqueNameNode.InnerText = $prefix + "_" + $UniqueName + "dialog"
    
    $xmlDoc.Save($dialogsRootPath)
    Write-Host "Value updated successfully"
}
else {
    Write-Host "Node UniqueName not found"
}