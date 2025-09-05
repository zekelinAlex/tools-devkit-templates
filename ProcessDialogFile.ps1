# Script to find and replace dialogunknownexampleid in files
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = ""
)

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file '$InputFile' does not exist."
    exit 1
}

# Read the file content
$content = Get-Content -Path $InputFile -Raw

# Check if dialogunknownexampleid exists in the file
if ($content -match "dialogunknownexampleid") {
    Write-Host "Found 'dialogunknownexampleid' in file: $InputFile"
    
    # Generate output filename if not provided
    if ([string]::IsNullOrEmpty($OutputFile)) {
        $fileInfo = Get-Item $InputFile
        $OutputFile = Join-Path $fileInfo.DirectoryName "$($fileInfo.BaseName)_processed$($fileInfo.Extension)"
    }
    
    # Replace dialogunknownexampleid with a new GUID
    $newGuid = (New-Guid).Guid
    $newContent = $content -replace "dialogunknownexampleid", $newGuid
    
    # Save the modified content to new file
    $newContent | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "Processed file saved as: $OutputFile"
    Write-Host "Replaced 'dialogunknownexampleid' with GUID: $newGuid"
    
    # Count occurrences
    $occurrences = ([regex]::Matches($content, "dialogunknownexampleid")).Count
    Write-Host "Total occurrences replaced: $occurrences"
} else {
    Write-Host "No occurrences of 'dialogunknownexampleid' found in file: $InputFile"
}

# Example usage:
# .\ProcessDialogFile.ps1 -InputFile "path\to\your\file.xml"
# .\ProcessDialogFile.ps1 -InputFile "path\to\your\file.xml" -OutputFile "path\to\output\file.xml"
