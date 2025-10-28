$ccproj_projectpath = "examplepluginprojectpath"

$projectDir = Split-Path $ccproj_projectpath

$pluginBasePath = Join-Path $projectDir "PluginBase.cs"

$namespace = (Get-Content $pluginBasePath | Select-String -Pattern 'namespace\s+(.+)' -AllMatches).Matches[0].Groups[1].Value

$testBasePath = ".template.temp\TestBase.cs"

$testBaseContent = Get-Content $testBasePath -Raw

$testBaseContent = $testBaseContent -replace "pluginnamespaceexample", $namespace

$testBaseContent | Set-Content $testBasePath