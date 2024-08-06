#!/bin/bash

# Set up error handling
set -e

# Ensure we're in the user's home directory
cd "$HOME"

# Create a directory for the weights if it doesn't exist
weightsDir="rosetta_ml_weights"
mkdir -p "$weightsDir"
cd "$weightsDir"

# Function to check if a command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    else
        echo "$1 completed successfully"
    fi
}

# Function to download and extract a model using gdown
download_and_extract_gdown() {
    local file_id=$1
    local model_name=$2
    local extract_dir=$3

    echo "Downloading the $model_name model..."
    gdown --id "$file_id"
    check_status "$model_name model download"

    echo "Extracting the $model_name model..."
    mkdir -p "$model_name"
    tar -xzf *.tar.gz -C "$model_name"
    check_status "$model_name model extraction"

    # Move contents to match Windows structure
    mv "$model_name/$extract_dir"/* "$model_name/"
    rm -rf "$model_name/$extract_dir"

    # Clean up
    rm *.tar.gz

    echo "$model_name model has been successfully downloaded and extracted in $(pwd)/$model_name"
}

# Function to download AlphaFold2 weights using Docker
download_alphafold2_weights() {
    echo "Downloading AlphaFold2 weights..."
    mkdir -p alphafold2
    docker run --user $(id -u):$(id -g) -ti --rm \
        -v "$(pwd)/alphafold2:/cache:rw" \
        ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2 \
        python -m colabfold.download
    check_status "AlphaFold2 weights download"
    echo "AlphaFold2 weights have been successfully downloaded to $(pwd)/alphafold2"
}

# Check if gdown is installed, if not, install it
if ! command -v gdown &> /dev/null; then
    echo "gdown is not installed. Installing gdown..."
    pip install gdown
    check_status "gdown installation"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Download and extract ESM model
download_and_extract_gdown "11odkcNsUTf8wnbfNJMEXpBKbevbDfh4f" "esm2_t30_150M_UR50D" "ML_graphs-main-tensorflow_graphs-ESM-esm2_t30_150M_UR50D/tensorflow_graphs/ESM/esm2_t30_150M_UR50D"

# Download and extract MIF-ST model
download_and_extract_gdown "1q1fRusKhNpnphUSbPeAewOp0Zl6xreXS" "mifst" "ML_graphs-main-pytorch_graphs-MIF-ST/pytorch_graphs/MIF-ST"

# Download AlphaFold2 weights
download_alphafold2_weights

echo "All models have been downloaded and extracted successfully."
echo "You can find the extracted files in the following directories:"
echo "ESM model: $HOME/$weightsDir/esm2_t30_150M_UR50D"
echo "MIF-ST model: $HOME/$weightsDir/mifst"
echo "AlphaFold2 weights: $HOME/$weightsDir/alphafold2"