param(
    [string]$ReleaseType = "patch",
    [string]$CommitMessage = "For release $Tag"
)

# Configuration variables
$Filename = "mmalabanan_resume"
$Resumes = ".\$Filename.docx", ".\$Filename.pdf"
$Archive = ".\$Filename.zip"
$OneDrive = "C:\Users\mmala\OneDrive\Documents\resume"


# ----------------------------------------------------------------------------------------------------------------
# Main function of script
# ----------------------------------------------------------------------------------------------------------------
try {
    # ------------------------------------------------------------------------------------------------------------
    # Check availability of git
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Check availability of git"
    & git --version | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Cannot find git. Installation of git maybe required." }

    # ------------------------------------------------------------------------------------------------------------
    # Copy resumes to OneDrive
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Copy resumes to OneDrive"
    $CopyFiles = @{
        Path = $Resumes
        Destination = $OneDrive
    }
    try{
        Copy-Item -Force @CopyFiles
    }
    catch {
        throw "Was not able to copy $Resumes to OneDrive."
    }

    # ------------------------------------------------------------------------------------------------------------
    # Remove the old archive
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Remove the old archive"
    if (Test-Path -Path $Archive -PathType Leaf) {
        try {
            Remove-Item -Force $Archive
        }
        catch {
            throw "Unable to remove old archive."
        }
    }

    # ------------------------------------------------------------------------------------------------------------
    # Create an archive
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Create an archive"
    $CompressFiles = @{
        LiteralPath= $Resumes
        CompressionLevel = "Optimal"
        DestinationPath = $Archive
    }
    try {
        Compress-Archive @CompressFiles
    }
    catch {
        throw "Cannot create $Archive."
    }

    # ------------------------------------------------------------------------------------------------------------
    # Get tag
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Get the latest tag"
    [int]$major, [int]$minor, [int]$patch = (& git describe --tags --abbrev=0) -split "\."
    if ($LASTEXITCODE -ne 0) { throw "Unable to get latest tag." }

    # ------------------------------------------------------------------------------------------------------------
    # Update tag
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Update tag"
    if ("patch" -eq $releaseType) {
        $patch = $patch + 1;
    }
    elseif ("minor" -eq $releaseType) {
        $minor = $minor + 1;
        $patch = 0;
    }
    elseif ("major" -eq $releaseType){
        $major = $major + 1;
        $minor = 0;
        $patch = 0;
    }
    else {
        throw "Unknown release type."
    }

    [string]$Tag = "$major.$minor.$patch"

    # ------------------------------------------------------------------------------------------------------------
    # Git add changed resume and archive
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Stage resume and archive"
    & git add $Resumes $Archive
    if ($LASTEXITCODE -ne 0) { throw "Unable to stage $Resumes or $Archive." }

    # ------------------------------------------------------------------------------------------------------------
    # Git commit changed resume and archive
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Commit resume and archive"
    & git commit -m "$CommitMessage"
    if ($LASTEXITCODE -ne 0) { throw "Unable to commit." }

    # ------------------------------------------------------------------------------------------------------------
    # Git tag
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Tag the lastest commit with $Tag"
    & git tag $Tag
    if ($LASTEXITCODE -ne 0) { throw "Unable to create tag." }

    # ------------------------------------------------------------------------------------------------------------
    # Git push
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Push the latest changes to github"
    & git push
    if ($LASTEXITCODE -ne 0) { throw "Unable to push to github." }

    # ------------------------------------------------------------------------------------------------------------
    # Git push tags
    # ------------------------------------------------------------------------------------------------------------
    Write-Host "Push the latest tag"
    & git push --tags
    if ($LASTEXITCODE -ne 0) { throw "Unable to push tags to github." }
}
catch {
    "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    exit 1
}