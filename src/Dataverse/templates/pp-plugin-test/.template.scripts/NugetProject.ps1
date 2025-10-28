cd "exampleplugintestprojectname\obj\"
dotnet new mstest --framework net462 -n "NugetProject"

dotnet add "NugetProject" package Microsoft.IdentityModel.Clients.ActiveDirectory --version 3.19.8
dotnet add "NugetProject" package Microsoft.CrmSdk.XrmTooling.CoreAssembly --version 9.1.0.1
dotnet add "NugetProject" package System.Runtime.CompilerServices.Unsafe
dotnet add "NugetProject" package Newtonsoft.Json

cd "NugetProject"
dotnet build
cd ..\..\..\
dotnet restore *> $null