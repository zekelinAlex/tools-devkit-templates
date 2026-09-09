$ErrorActionPreference = 'Stop'

# Single interim post-action: all XML mutations run in-process inside the TALXIS CLI
# (txc workspace component apply-scaffold), backed by the platform metadata library.

& txc workspace component apply-scaffold `
    --component-type 'FormSubgrid' `
    --solution-root '__solution-declarations-root__' `
    --file 'row=.template.temp/subgrid.xml' `
    --param 'entity=__entity-logical-name__' `
    --param 'form-type=__form-type__' `
    --param 'form-id=__form-id__'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Remove-Item .template.scripts -Recurse -Force
Remove-Item .template.temp -Recurse -Force
