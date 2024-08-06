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

# Function to install gdown
install_gdown() {
    if [ "$(id -u)" -eq 0 ]; then
        # Running as root (sudo), use apt-get
        apt-get update
        apt-get install -y python3-pip
        pip3 install gdown
    else
        # Running as normal user, use pip
        pip install gdown
    fi
    check_status "gdown installation"
}

# Ensure we're in the user's home directory
if [ "$(id -u)" -eq 0 ]; then
    # If running as root, use the invoking user's home directory
    SUDO_USER_HOME=$(eval echo ~$SUDO_USER)
    cd "$SUDO_USER_HOME"
else
    cd "$HOME"
fi

# Create a directory for the weights if it doesn't exist
weightsDir="rosetta_ml_weights"
mkdir -p "$weightsDir"
cd "$weightsDir"

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
    sudo chmod 777 alphafold2  # Ensure directory has full permissions

    # Run the Docker command with proper permissions
    docker run --rm \
        -v "$(pwd)/alphafold2:/cache:rw" \
        --user "$(id -u):$(id -g)" \
        ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2 \
        bash -c "mkdir -p /cache/colabfold/params && python -m colabfold.download"

    check_status "AlphaFold2 weights download"
    echo "AlphaFold2 weights have been successfully downloaded to $(pwd)/alphafold2"
}

# Check if gdown is installed, if not, install it
if ! command -v gdown &> /dev/null; then
    echo "gdown is not installed. Installing gdown..."
    install_gdown
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Download and extract ESM model
#download_and_extract_gdown "11odkcNsUTf8wnbfNJMEXpBKbevbDfh4f" "esm2_t30_150M_UR50D" "ML_graphs-main-tensorflow_graphs-ESM-esm2_t30_150M_UR50D/tensorflow_graphs/ESM/esm2_t30_150M_UR50D"

# Download and extract MIF-ST model
#download_and_extract_gdown "1q1fRusKhNpnphUSbPeAewOp0Zl6xreXS" "mifst" "ML_graphs-main-pytorch_graphs-MIF-ST/pytorch_graphs/MIF-ST"

# Download AlphaFold2 weights
download_alphafold2_weights

echo "All models have been downloaded and extracted successfully."
echo "You can find the extracted files in the following directories:"
echo "ESM model: $(pwd)/esm2_t30_150M_UR50D"
echo "MIF-ST model: $(pwd)/mifst"
echo "AlphaFold2 weights: $(pwd)/alphafold2"

# Echo the command to run AlphaFold2 manually
echo ""
echo "To run AlphaFold2 manually, use the following command (replace /path/to/input and /path/to/output with your actual paths):"
echo "docker run --rm -it -v $(pwd)/alphafold2:/cache:ro -v /path/to/input:/mnt/input -v /path/to/output:/mnt/output ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2 colabfold_batch /mnt/input/your_fasta_file.fasta /mnt/output --use_gpu"
echo ""
echo "Make sure to replace '/path/to/input' with the directory containing your FASTA file, and '/path/to/output' w