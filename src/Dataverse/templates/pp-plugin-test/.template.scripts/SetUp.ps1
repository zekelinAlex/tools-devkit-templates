dotnet new mstest --framework net462 -n "exampleplugintestprojectname"

if ("examplepluginprojectpath" -ne "unknown") {
    dotnet add "exampleplugintestprojectname" reference "examplepluginprojectpath"
}

dotnet remove "exampleplugintestprojectname" package MSTest
dotnet add "exampleplugintestprojectname" package XrmMockup365
dotnet add "exampleplugintestprojectname" package MSTest.TestAdapter
dotnet add "exampleplugintestprojectname" package MSTest.TestFramework

$pkgRoot = "$env:USERPROFILE\.nuget\packages\xrmmockup365"

if (-not (Test-Path $pkgRoot)) {
    cd "exampleplugintestprojectname"
    dotnet build 
    cd ..
}

$ver     = Get-ChildItem $pkgRoot | Sort-Object Name -Descending | Select-Object -First 1
$src     = Join-Path $ver.FullName "content\net462\Metadata"
$dst     = "exampleplugintestprojectname"
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item -Path $src -Destination $dst -Recurse -Force


$csproj = "exampleplugintestprojectname\exampleplugintestprojectname.csproj"
$content = Get-Content $csproj

$beforeEnd = $content[0..($content.Count-2)]
$afterEnd = $content[-1]

$toInsert = @(
'  <ItemGroup>',
'    <Compile Include="Metadata\TypeDeclarations.cs" />',
'    <None Include="Metadata\**\*.*">',
'      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>',
'    </None>',
'  </ItemGroup>'
)

$newContent = $beforeEnd + $toInsert + $afterEnd
$newContent | Set-Content $csproj

./.template.scripts\RestoreNugetPackages.ps1

Remove-Item "exampleplugintestprojectname\Metadata\MetadataGenerator365.exe.config" -Recurse -Force

$metadataConfigFile = ".template.temp\MetadataGenerator365.exe.config"
$metadataFolder = "exampleplugintestprojectname\Metadata"

Copy-Item -Path $metadataConfigFile -Destination $metadataFolder -Force

Remove-Item "exampleplugintestprojectname\Test1.cs" -Recurse -Force

Copy-Item -Path ".template.temp\TestBase.cs" -Destination "exampleplugintestprojectname" -Force

cd "exampleplugintestprojectname\Metadata\"
./MetadataGenerator*.exe
cd ..\..\

