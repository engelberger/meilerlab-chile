#!/bin/bash

# Path to the downloaded ESM model
ESM_MODEL_PATH="$HOME/params/ESM/esm2_t30_150M_UR50D"

# Path to the downloaded MIF-ST model
MIFST_MODEL_PATH="$HOME/params/MIF-ST"

# Path to the tutorial files
TUTORIAL_PATH="$(pwd)"

# Path to rosetta
ROSETTA_PATH="$HOME/Documents/Binaries/rosetta"

# Run the Docker container
docker run -it \
  -v "$ESM_MODEL_PATH":/usr/local/database/protocol_data/tensorflow_graphs/tensorflow_graph_repo_submodule/ESM/esm2_t30_150M_UR50D \
  -v "$MIFST_MODEL_PATH":/usr/local/database/protocol_data/inverse_folding/mifst \
  -v "$TUTORIAL_PATH":/work \
  -v "$ROSETTA_PATH":/rosetta_host \
  -w /work \
  rosettacommons/rosetta:ml \
  /bin/bash

echo "Docker container exited"
