param([string]$release_type = "patch")

# Configuration variables
$filename = "mmalabanan_resume"
$resumes = ".\$filename.docx", ".\$filename.pdf"
$archive = ".\$filename.zip"
$onedrive = "C:\Users\mmala\OneDrive\Documents\resume"



try {
    # check to see if git is available
    & git --version | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Cannot find git. Installation of git maybe required." }

    # copy resumes to OneDrive
    $copy_files = @{
        Path = $resumes
        Destination = $onedrive
    }
    try{
        Copy-Item -Force @copy_files
    }
    catch {
        throw "Was not able to copy $resumes to OneDrive."
    }

    # remove the old archive
    if (Test-Path -Path $archive -PathType Leaf) {
        Remove-Item -Force $archive
    }

    # create an archive
    $compress_files = @{
        LiteralPath= $resumes
        CompressionLevel = "Optimal"
        DestinationPath = $archive
    }
    try {
        Compress-Archive @compress_files
    }
    catch {
        throw "Cannot create $archive."
    }

}
catch {
    "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}