#!/bin/bash

# Set up error handling
set -e

# Function to check if a command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    else
        echo "$1 completed successfully"
    fi
}

# Function to download and extract a model
download_and_extract() {
    local file_id=$1
    local model_name=$2
    local extract_dir=$3

    mkdir -p "$model_name"
    cd "$model_name"

    echo "Downloading the $model_name model..."
    gdown --id "$file_id"
    check_status "$model_name model download"

    echo "Extracting the $model_name model..."
    tar -xzf *.tar.gz
    check_status "$model_name model extraction"

    mv "$extract_dir"/* .
    #rm -rf "$extract_dir" *.tar.gz

    echo "$model_name model has been successfully downloaded and extracted in $(pwd)"
    cd ..
}

# Check if gdown is installed, if not, install it
if ! command -v gdown &> /dev/null; then
    echo "gdown is not installed. Installing gdown..."
    pip install gdown
    check_status "gdown installation"
fi

# Download and extract ESM model
download_and_extract "11odkcNsUTf8wnbfNJMEXpBKbevbDfh4f" "esm2_t30_150M_UR50D" "ML_graphs-main-tensorflow_graphs-ESM-esm2_t30_150M_UR50D/tensorflow_graphs/ESM/esm2_t30_150M_UR50D"

# Download and extract MIF-ST model
download_and_extract "1q1fRusKhNpnphUSbPeAewOp0Zl6xreXS" "mifst" "ML_graphs-main-pytorch_graphs-MIF-ST/pytorch_graphs/MIF-ST"

echo "All models have been downloaded and extracted successfully."