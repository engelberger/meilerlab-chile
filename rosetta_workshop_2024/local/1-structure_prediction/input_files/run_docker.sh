#!/bin/bash

# Path to the downloaded AlphaFold2 params
AF2_MODEL_PATH="$HOME/rosetta_ml_weights/alphafold2"

# Path to the tutorial files
TUTORIAL_PATH="$(pwd)"

# Run the Docker container
docker run --user $(id -u) -it --rm \
   -v "$AF2_MODEL_PATH":/cache \
   -v "$TUTORIAL_PATH":/work \
   -w /work \
   ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2

echo "Docker container exited"
