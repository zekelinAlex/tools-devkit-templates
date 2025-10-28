Write-Host "Restoring Nuget Packages" -NoNewline

$job = Start-Job -ScriptBlock {
    & {
        ./.template.scripts\NugetProject.ps1

        $librariesFolder = "exampleplugintestprojectname\obj\NugetProject\bin\Debug\net462"
        $metadataFolder = "exampleplugintestprojectname\Metadata"
        
        $excludedLibs = @(
            "Microsoft.Crm.Sdk.Proxy.dll",
            "Microsoft.IdentityModel.Clients.ActiveDirectory.dll",
            "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll",
            "Microsoft.Xrm.Sdk.dll",
            "Microsoft.Xrm.Tooling.Connector.dll",
            "Newtonsoft.Json.dll",
            "System.Runtime.CompilerServices.Unsafe.dll"
        )
        
        if (Test-Path $librariesFolder) {
            foreach ($dllName in $excludedLibs) {
                $srcPath = Join-Path $librariesFolder $dllName
                if (Test-Path $srcPath) {
                    Copy-Item -Path $srcPath -Destination $metadataFolder -Force
                }
            }
        }
        
        Remove-Item "exampleplugintestprojectname\obj\NugetProject" -Recurse -Force
    }
}

$spinner = @(".", "..", "...")
$index = 0

while ($job.State -eq "Running") {
    $dots = $spinner[$index]
    $index = ($index + 1) % $spinner.Count

    Write-Host "`rRestoring Nuget Packages$dots" -NoNewline
    Start-Sleep -Milliseconds 500
}

Receive-Job $job *> $null | Out-Null
Remove-Job $job

Write-Host "`rRestoring Nuget Packages... Done!" 
