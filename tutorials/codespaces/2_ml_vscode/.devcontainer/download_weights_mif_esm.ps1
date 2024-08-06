# PowerShell script to download weights using gdown

# Ensure we're in the user's home directory
Set-Location $env:USERPROFILE

# Create a directory for the weights if it doesn't exist
$weightsDir = "rosetta_ml_weights"
New-Item -ItemType Directory -Force -Path $weightsDir
Set-Location $weightsDir

# Function to install gdown if not already installed
function Install-Gdown {
    try {
        # Check if gdown is installed
        python -m gdown --version
    }
    catch {
        Write-Host "gdown is not installed. Installing gdown..."
        pip install gdown --user
    }
}

# Function to install 7-Zip if not already installed
function Install-7Zip {
    if (-not (Test-Path "${env:ProgramFiles}\7-Zip\7z.exe")) {
        Write-Host "7-Zip is not installed. Installing 7-Zip..."
        $dlurl = 'https://7-zip.org/' + (Invoke-WebRequest -UseBasicParsing -Uri 'https://7-zip.org/' | 
            Select-Object -ExpandProperty Links | 
            Where-Object {($_.outerHTML -match 'Download')-and ($_.href -like "a/*") -and ($_.href -like "*-x64.exe")} | 
            Select-Object -First 1 | 
            Select-Object -ExpandProperty href)
        $installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)
        Invoke-WebRequest $dlurl -OutFile $installerPath
        Start-Process -FilePath $installerPath -Args "/S" -Verb RunAs -Wait
        Remove-Item $installerPath
        Write-Host "7-Zip has been installed successfully."
    }
}

# Function to download and extract a model
function Download-And-Extract-Model {
    param (
        [string]$fileId,
        [string]$modelName,
        [string]$extractDir
    )
    
    Write-Host "Downloading the $modelName model..."
    python -m gdown --id $fileId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: $modelName model download failed"
        exit 1
    }
    
    Write-Host "$modelName model download completed successfully"
    
    # Find the downloaded file
    $downloadedFile = Get-ChildItem -Filter *.tar.gz | Select-Object -First 1
    
    if ($null -eq $downloadedFile) {
        Write-Host "Error: Cannot find downloaded .tar.gz file"
        exit 1
    }
    
    # Check file integrity
    $fileInfo = Get-Item $downloadedFile.FullName
    Write-Host "Downloaded file information:"
    Write-Host "Name: $($fileInfo.Name)"
    Write-Host "Size: $($fileInfo.Length) bytes"
    Write-Host "Last Modified: $($fileInfo.LastWriteTime)"
    
    if ($fileInfo.Length -lt 1000000) {  # Less than 1MB
        Write-Host "Warning: File size is suspiciously small. The download may have failed or the file may be corrupt."
        exit 1
    }
    
    Write-Host "Extracting the $modelName model..."
    
    # Create a directory for the extracted files
    $extractPath = Join-Path $PWD $modelName
    New-Item -ItemType Directory -Force -Path $extractPath
    
    # Extract using 7-Zip (two-step process)
    # Step 1: Extract .tar.gz to .tar
    & "${env:ProgramFiles}\7-Zip\7z.exe" x $downloadedFile.FullName "-o$extractPath" -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to extract .tar.gz file"
        exit 1
    }
    
    # Step 2: Extract .tar
    $tarFile = Get-ChildItem -Path $extractPath -Filter *.tar | Select-Object -First 1
    if ($null -ne $tarFile) {
        & "${env:ProgramFiles}\7-Zip\7z.exe" x $tarFile.FullName "-o$extractPath" -y
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to extract .tar file"
            exit 1
        }
        # Remove the intermediate .tar file
        Remove-Item -Path $tarFile.FullName -Force
    }
    else {
        Write-Host "Warning: No .tar file found after initial extraction"
    }
    
    Write-Host "$modelName model extraction completed successfully"
    
    # Remove the original compressed file to save space
    Remove-Item -Path $downloadedFile.FullName -Force
    
    Write-Host "Extracted files are located in: $extractPath"
}

# Main script execution
try {
    # Install gdown
    Install-Gdown

    # Install 7-Zip
    Install-7Zip

    # Download and extract ESM model
    Download-And-Extract-Model -fileId "11odkcNsUTf8wnbfNJMEXpBKbevbDfh4f" `
                               -modelName "esm2_t30_150M_UR50D" `
                               -extractDir "ML_graphs-main-tensorflow_graphs-ESM-esm2_t30_150M_UR50D\tensorflow_graphs\ESM\esm2_t30_150M_UR50D"

    # Download and extract MIF-ST model
    Download-And-Extract-Model -fileId "1q1fRusKhNpnphUSbPeAewOp0Zl6xreXS" `
                               -modelName "mifst" `
                               -extractDir "ML_graphs-main-pytorch_graphs-MIF-ST\pytorch_graphs\MIF-ST"

    Write-Host "All models have been downloaded and extracted successfully."
    Write-Host "You can find the extracted files in the following directories:"
    Write-Host "ESM model: $PWD\esm2_t30_150M_UR50D"
    Write-Host "MIF-ST model: $PWD\mifst"
}
catch {
    Write-Host "An error occurred: $_"
    exit 1
}