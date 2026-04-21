$lowercasename = "entityexamplelogicalname"
$capitalizedname = $lowercasename.Substring(0,1).ToUpper() + $lowercasename.Substring(1)

$targetGenerated = "src\generated"
$targetIndexTs = Join-Path $targetGenerated "index.ts"

if (-not (Test-Path $targetIndexTs)) 
{
    New-Item -ItemType Directory -Path $targetGenerated -Force | Out-Null

    Copy-Item ".template.temp\models" -Destination $targetGenerated -Recurse -Force
    Copy-Item ".template.temp\index.ts" -Destination $targetGenerated -Force
}

.\.template.scripts\ReplacePlaceholder.ps1 -FilePath "src\generated\services\capitalizedentitylogicalnameexamplesService.ts" -Placeholder "lowercaseentitylogicalnameexample" -Replacement $lowercasename
.\.template.scripts\ReplacePlaceholder.ps1 -FilePath "src\generated\services\capitalizedentitylogicalnameexamplesService.ts" -Placeholder "capitalizedentitylogicalnameexample" -Replacement $capitalizedname

Start-Process dotnet-script -ArgumentList '".\.template.scripts\GenerateModel.csx" -- "modelsolutionexamplepath" "entityexamplelogicalname" "src\generated\models"' -NoNewWindow -Wait

$modelIndexString = "export * as "+ $capitalizedname + "sModel from './models/"+ $capitalizedname + "sModel';"
$serviceIndexString = "export * from './services/" + $capitalizedname + "sService';"

.\.template.scripts\InsertAfterTarget.ps1 -TargetString "// Models" -SettingString $modelIndexString -FilePath "src\generated\index.ts"
.\.template.scripts\InsertAfterTarget.ps1 -TargetString "// Services" -SettingString $serviceIndexString -FilePath "src\generated\index.ts"

.\.template.scripts\AddDataSource.ps1

.\.template.scripts\AddDataSourceInfo.ps1 -SolutionPath "modelsolutionexamplepath" -EntityLogicalName "entityexamplelogicalname" -FilePath ".power\schemas\appschemas\dataSourcesInfo.ts"

Start-Process dotnet-script -ArgumentList '".\.template.scripts\GenerateSchema.csx" -- "modelsolutionexamplepath" "entityexamplelogicalname" ".power\schemas\dataverse"' -NoNewWindow -Wait