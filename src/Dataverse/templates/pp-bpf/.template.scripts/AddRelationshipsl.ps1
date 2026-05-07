# Resolve the relative path to an absolute path (to support other OSes)
$solutionPath = Resolve-Path -Path '__solution-declarations-root__/Other/Relationships.xml'

# Load the XML file
[XML]$File = Get-Content -Path $solutionPath -Raw
$rootComponents = $File.SelectSingleNode("//EntityRelationships")

$newComponent = $File.CreateElement("EntityRelationship")
$newComponent.SetAttribute("Name", 'bpf___entity-logical-name_____publisher-prefix_____bpf-name__')

$null = $rootComponents.AppendChild($newComponent)

$null = $rootComponents.AppendChild($newComponent2)

# Save the updated XML back to the file
$File.Save($solutionPath)
