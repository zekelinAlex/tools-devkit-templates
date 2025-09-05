$dialogId = "dialogexampleid"

if ($dialogId -eq "dialogunknownexampleid") {
    $dialogId = (New-Guid).Guid

    $OutputFile = Join-Path $fileInfo.DirectoryName "${$dialogId}}$($fileInfo.Extension)"
    
    $newContent = $content -replace "dialogunknownexampleid", $dialogId
    
    $newContent | Out-File -FilePath $OutputFile -Encoding UTF8
}
