$targetDir = "__solution-declarations-root__/Workflows"

$guid = [guid]::NewGuid().ToString()
$guidUpper = $guid.ToUpperInvariant()
$guidLower = $guid.ToLowerInvariant()

$files = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object {
    (Get-Content $_.FullName -Raw) -match '__talxis-flow-workflow-id__|__talxis-flow-workflow-id__' -or
    $_.Name -match '__talxis-flow-workflow-id__'
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace '__talxis-flow-workflow-id__', $guidUpper
    $content = $content -replace '__talxis-flow-workflow-id__', $guidLower
    Set-Content -Path $file.FullName -Value $content -NoNewline
}

$filesToRename = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object { $_.Name -like '*__talxis-flow-workflow-id__*' }
foreach ($file in $filesToRename) {
    $newName = $file.Name -replace '__talxis-flow-workflow-id__', $guidUpper
    Rename-Item -Path $file.FullName -NewName $newName
}

$filePath = ".template.scripts/FlowWorkflowID.txt"
Set-Content -Path $filePath -Value $guid -NoNewline
