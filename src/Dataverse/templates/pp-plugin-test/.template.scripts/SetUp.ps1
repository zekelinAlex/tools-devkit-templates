dotnet new mstest --framework net462 -n "exampleplugintestprojectname"


if ("examplepluginprojectpath" -ne "unknown") {
    dotnet add "exampleplugintestprojectname" reference "examplepluginprojectpath"
}

dotnet add "exampleplugintestprojectname" package XrmMockup365
dotnet add "exampleplugintestprojectname" package MSTest.TestAdapter
dotnet add "exampleplugintestprojectname" package MSTest.TestFramework
dotnet remove "exampleplugintestprojectname" package MSTest

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

$ver  = "9.0.2.59"
$root = "$env:USERPROFILE\.nuget\packages\microsoft.crmsdk.coreassemblies\$ver\lib\net462"
$dst  = "exampleplugintestprojectname\Metadata"

Copy-Item "$root\Microsoft.Xrm.Sdk.dll"       -Destination $dst -Force
Copy-Item "$root\Microsoft.Crm.Sdk.Proxy.dll" -Destination $dst -Force

$toolingRoot = "$env:USERPROFILE\.nuget\packages\microsoft.crmsdk.xrmtooling.coreassembly"
$toolingVer  = (Get-ChildItem $toolingRoot | Sort-Object Name -Descending | Select-Object -First 1).Name
$toolingLib  = Join-Path $toolingRoot "$toolingVer\lib\net462"
Copy-Item (Join-Path $toolingLib "Microsoft.Xrm.Tooling.Connector.dll") -Destination $dst -Force

# Newtonsoft.Json
$newtonRoot = "$env:USERPROFILE\.nuget\packages\newtonsoft.json"
if (Test-Path $newtonRoot) {
  $newtonVer = (Get-ChildItem $newtonRoot | Sort-Object Name -Descending | Select-Object -First 1).Name
  $newtonLib = Join-Path $newtonRoot "$newtonVer\lib\net45"
  if (Test-Path (Join-Path $newtonLib "Newtonsoft.Json.dll")) {
    Copy-Item (Join-Path $newtonLib "Newtonsoft.Json.dll") -Destination $dst -Force
  }
}

# ADAL
$adalRoot = "$env:USERPROFILE\.nuget\packages\microsoft.identitymodel.clients.activedirectory"
if (Test-Path $adalRoot) {
  $adalVer = (Get-ChildItem $adalRoot | Sort-Object Name -Descending | Select-Object -First 1).Name
  $adalLibs = @(
    Join-Path $adalRoot "$adalVer\lib\net461",
    Join-Path $adalRoot "$adalVer\lib\net45"
  )
  foreach ($p in $adalLibs) {
    $adalDll = Join-Path $p "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    if (Test-Path $adalDll) {
      Copy-Item $adalDll -Destination $dst -Force
      break
    }
  }
}

$adalRoot = "$env:USERPROFILE\.nuget\packages\microsoft.identitymodel.clients.activedirectory"
$adalVer  = "3.19.8"
$libPaths = @(
  Join-Path $adalRoot "$adalVer\lib\net461",
  Join-Path $adalRoot "$adalVer\lib\net45"
)
$adalDll = $null
foreach ($p in $libPaths) {
  $candidate = Join-Path $p "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
  if (Test-Path $candidate) { $adalDll = $candidate; break }
}
if (-not $adalDll) { throw "ADAL dll not found in $adalRoot" }
Copy-Item $adalDll -Destination $dst -Force