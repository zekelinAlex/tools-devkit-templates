$ErrorActionPreference = 'Stop'

# Single interim post-action: all XML mutations run in-process inside the TALXIS CLI
# (txc workspace component apply-scaffold), backed by the platform metadata library.

& txc workspace component apply-scaffold `
    --component-type 'EntityView' `
    --solution-root '__solution-root-path__' `
    --param 'entity=exampleexistingentity'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Remove-Item .template.scripts -Recurse -Force
