$lowercasename = "__entity-logical-name__"
$capitalizedname = $lowercasename.Substring(0,1).ToUpper() + $lowercasename.Substring(1)
$modelSolutionPath = (Resolve-Path "__model-solution-path__").Path

$targetGenerated = Join-Path "src" "generated"
$targetIndexTs = Join-Path $targetGenerated "index.ts"

if (-not (Test-Path $targetIndexTs)) 
{
    New-Item -ItemType Directory -Path $targetGenerated -Force | Out-Null

    Copy-Item (Join-Path ".template.temp" "models") -Destination $targetGenerated -Recurse -Force
    Copy-Item (Join-Path ".template.temp" "index.ts") -Destination $targetGenerated -Force
}

& (Join-Path $PSScriptRoot 'ReplacePlaceholder.ps1') -FilePath (Join-Path "src" "generated" "services" "__capitalized-entity-logical-name__sService.ts") -Placeholder "__lowercase-entity-logical-name__" -Replacement $lowercasename
& (Join-Path $PSScriptRoot 'ReplacePlaceholder.ps1') -FilePath (Join-Path "src" "generated" "services" "__capitalized-entity-logical-name__sService.ts") -Placeholder "__capitalized-entity-logical-name__" -Replacement $capitalizedname

$generateModelScript = Join-Path $PSScriptRoot "GenerateModel.cs"
$generatedModelsPath = Join-Path "src" "generated" "models"

$genModelOutput = & dotnet run --file $generateModelScript -- $modelSolutionPath "__entity-logical-name__" $generatedModelsPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "GenerateModel.cs failed (exit code $LASTEXITCODE). Output: $genModelOutput"
    exit 1
}

$modelIndexString = "export * as "+ $capitalizedname + "sModel from './models/"+ $capitalizedname + "sModel';"
$serviceIndexString = "export * from './services/" + $capitalizedname + "sService';"

$generatedIndexTs = Join-Path "src" "generated" "index.ts"
& (Join-Path $PSScriptRoot 'InsertAfterTarget.ps1') -TargetString "// Models" -SettingString $modelIndexString -FilePath $generatedIndexTs
& (Join-Path $PSScriptRoot 'InsertAfterTarget.ps1') -TargetString "// Services" -SettingString $serviceIndexString -FilePath $generatedIndexTs

& (Join-Path $PSScriptRoot 'AddDataSource.ps1')

& (Join-Path $PSScriptRoot 'AddDataSourceInfo.ps1') -SolutionPath $modelSolutionPath -EntityLogicalName "__entity-logical-name__" -FilePath (Join-Path ".power" "schemas" "appschemas" "dataSourcesInfo.ts")

$generateSchemaScript = Join-Path $PSScriptRoot "GenerateSchema.cs"
$dataverseSchemasPath = Join-Path ".power" "schemas" "dataverse"

$genSchemaOutput = & dotnet run --file $generateSchemaScript -- $modelSolutionPath "__entity-logical-name__" $dataverseSchemasPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "GenerateSchema.cs failed (exit code $LASTEXITCODE). Output: $genSchemaOutput"
    exit 1
}
