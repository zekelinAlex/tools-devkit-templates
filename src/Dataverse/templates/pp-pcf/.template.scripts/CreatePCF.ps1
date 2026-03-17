$name = "examplesourcename"
$namespace = $name -replace '[^\p{L}\p{N}]', ''

pac pcf init --namespace $namespace --name $namespace --template field

Remove-Item -Path ".\$namespace.pcfproj" -Force
Copy-Item -Path ".template.temp\examplesourcename.csproj" -Destination ".\$namespace.csproj"