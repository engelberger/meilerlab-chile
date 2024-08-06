#!/bin/bash

# Set up error handling
set -e

# Path to the tutorial files
TUTORIAL_PATH="$(pwd)"

# Rosetta executable
ROSETTA_EXE="rosetta_scripts.cxx11threadserialization.linuxgccrelease"

# Run the Docker container and execute Rosetta command
docker run -it --rm \
  -v "$TUTORIAL_PATH":/work \
  -w /work \
  rosettacommons/rosetta:serial \
  bash -c "$ROSETTA_EXE @inputs/options -docking:ligand:ligand_ensemble 0 -nstruct 1 && echo 'Rosetta execution completed'"

echo "Docker container exited"

# Echo the command for manual execution
echo ""
echo "To run this command manually, use:"
echo "docker run -it --rm -v \"$(pwd)\":/work -w /work rosettacommons/rosetta:serial bash -c \"$ROSETTA_EXE @inputs/options -docking:ligand:ligand_ensemble 0 -nstruct 1\""