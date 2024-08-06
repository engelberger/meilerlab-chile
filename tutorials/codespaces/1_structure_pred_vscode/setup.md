# Setup Instructions for Downloading AlphaFold2 Weights

Before running the devcontainer for the next tutorial, we need to download the AlphaFold2 weights. We'll use Docker to do this, ensuring compatibility across different systems.

## Prerequisites

1. Ensure Docker is installed on your system. If not, download and install it from [Docker's official website](https://www.docker.com/products/docker-desktop).

2. Make sure you have at least 50GB of free disk space for the weights.

## Instructions

### For Unix-based systems (Linux/macOS):

1. Open a terminal.

2. Create the directory for the weights (if it doesn't exist already):
   ```bash
   mkdir -p ~/rosetta_ml_weights/alphafold2
   ```

3. Run the following Docker command to download the weights:
   ```bash
   docker run --user $(id -u):$(id -g) -ti --rm \
     -v ~/rosetta_ml_weights/alphafold2:/cache:rw \
     ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2 \
     python -m colabfold.download
   ```

### For Windows:

1. Open PowerShell as an administrator.

2. Create the directory for the weights (if it doesn't exist already):
   ```powershell
   New-Item -ItemType Directory -Force -Path $env:USERPROFILE\rosetta_ml_weights\alphafold2
   ```

3. Run the following Docker command to download the weights:
   ```powershell
   docker run --user 0:0 -ti --rm `
     -v ${env:USERPROFILE}\rosetta_ml_weights\alphafold2:/cache:rw `
     ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2 `
     python -m colabfold.download
   ```

## After Downloading

Once the download is complete, you should see the AlphaFold2 weights in the `~/rosetta_ml_weights/alphafold2` directory (Unix) or `%USERPROFILE%\rosetta_ml_weights\alphafold2` directory (Windows).


## Next Steps

With the AlphaFold2 weights downloaded and the devcontainer configuration updated, you're now ready to proceed with the next tutorial using the devcontainer.