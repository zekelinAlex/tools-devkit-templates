$targetDir = "__solution-declarations-root__/Workflows"  

$guid = [guid]::NewGuid().ToString()
$guidUpper = $guid.ToUpperInvariant()
$guidLower = $guid.ToLowerInvariant()
$guidNoDashes = $guid -replace '-', ''

$files = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object {
    (Get-Content $_.FullName -Raw) -match '__talxis-workflow-unique-id-capital__|__talxis-workflow-unique-id__' -or
    $_.Name -like '*__talxis-workflow-unique-id-capital__*'
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    $content = $content -replace '__talxis-workflow-unique-id-capital__', $guidUpper

    $content = $content -replace '__talxis-workflow-unique-id__', $guidLower

    $content = $content -replace '___talxis-workflow-no-dashes-id___', $guidNoDashes

    Set-Content -Path $file.FullName -Value $content
}

$filesToRename = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object { $_.Name -like '*__talxis-workflow-unique-id-capital__*' }
foreach ($file in $filesToRename) {
    $newName = $file.Name -replace '__talxis-workflow-unique-id-capital__', $guidUpper
    $newPath = Join-Path $file.DirectoryName $newName
    Rename-Item -Path $file.FullName -NewName $newName
}


$filePath = ".template.scripts\WorkflowsID.txt"

Set-Content -Path $filePath -Value $guid