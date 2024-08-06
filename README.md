# Rosetta Workshop 2024 - Santiago, Chile

Welcome to the official repository for the Rosetta Workshop 2024, taking place in Santiago, Chile from August 5-7. This workshop offers an immersive experience in computational structural biology and drug discovery using cutting-edge tools and methodologies.

## Workshop Overview

The Rosetta Workshop 2024 combines comprehensive lectures with practical tutorials, focusing on three key areas:

1. Protein Structure Prediction
2. Ligand Docking and Small Molecule Discovery
3. Machine Learning Approaches in Rosetta for Protein Design

This workshop is designed for bachelor to PhD students, postdoctoral researchers, and professionals in Computational Biology, Biological Sciences, Biological Engineering, and related fields.

## Repository Structure

```
rosetta_workshop_2024/
│
├── local/
│   ├── 1-structure_prediction/
│   ├── 2-ligand_docking/
│   ├── 3_bcl_qsar/
│   ├── 4-rosetta_ml_tutorial/
│   ├── 1-structure_prediction.md
│   ├── 2-ligand_docking_tutorial.md
│   └── 4-rosetta_ml_tutorial.md
│
├── download_weights.sh
└── README.md
```

## Tutorials

### 1. Protein Structure Prediction (`1-structure_prediction.md`)
This tutorial covers the application of AlphaFold2 via ColabFold for protein structure prediction, including:
- Prediction of monomeric and multimeric structures
- Exploration of alternative conformations
- Analysis and interpretation of prediction results

### 2. Ligand Docking (`2-ligand_docking_tutorial.md`)
The ligand docking tutorial focuses on RosettaLigand, covering:
- Standard ligand docking procedures
- Ensemble docking approaches
- Analysis of docking results and scoring methodologies

### 3. Machine Learning in Rosetta (`4-rosetta_ml_tutorial.md`)
This tutorial explores the integration of machine learning techniques in Rosetta for protein design:
- Utilization of ProteinMPNN for mutation prediction
- Application of ESM (Evolutionary Scale Modeling) for sequence analysis
- Implementation of MIF-ST (Masked Inverse Folding with Sequence Transfer) for design tasks

## Prerequisites

Participants should have:
- Foundational knowledge of protein structure and drug discovery concepts
- Familiarity with the Linux command line interface
- Familiarity in Python programming (version 3.7 or higher)

## Setup Instructions

For workshop participants:

1. The repository is pre-cloned in your workstation's home directory. Navigate to it:
   ```
   cd ~/meilerlab-chile/rosetta_workshop_2024/local
   ```

2. All required software (Docker, Conda, PyMOL) is pre-installed on your workstation.

3. The conda environment is pre-configured. Activate it with:
   ```
   conda activate RAI_workshop
   ```

4. Required model weights are pre-downloaded.

5. For each tutorial, navigate to the corresponding directory in the `local` folder and follow the instructions in the respective Markdown file.

For post-workshop use:

To replicate the workshop environment on your personal machine:

1. Install Conda, Docker, and PyMOL on your system.
2. Create and activate the Conda environment:
   ```
   conda create -n rosetta_workshop python=3.9
   conda activate rosetta_workshop
   conda install -c schrodinger pymol
   ```
3. Clone the repository and navigate to it.
4. Download the required weights:
   ```
   bash download_weights.sh
   ```

Please note that setting up these dependencies can be complex. If you encounter any issues, do not hesitate to seek assistance.

## Workshop Information

**Dates:** August 5-7, 2024

**Location:** 
Pontificia Universidad Católica de Chile
Campus San Joaquin
Av Vicuña Mackenna 4860, Macul
Santiago 7820436, Chile

**Organizers:** 
- Professor Jens Meiler - Alexander von Humboldt Professor and Director, Institute for Drug Discovery, Leipzig University; Distinguished Research Professor, Center for Structural Biology, Vanderbilt University
- Professor César Ramírez-Sarmiento - Associate Professor, Institute for Biological and Medical Engineering, Pontificia Universidad Católica de Chile; Adjunct Researcher, Millennium Institute for Integrative Biology

**Instructors:**
- Felipe Engelberger - PhD Candidate, University of Leipzig
- Luisa Krämer - Master's Student, University of Leipzig

## Additional Information
TBD

For any inquiries or technical issues during the workshop, please consult the instructors. If you're following these tutorials outside the workshop context and encounter difficulties, please create an issue in this repository.

We look forward to your participation in this exploration of advanced computational methods in structural biology and drug discovery.