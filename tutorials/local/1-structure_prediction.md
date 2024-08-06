# Structure Prediction with AlphaFold Using Docker ColabFold

## Introduction

In this tutorial, we will explore how to use AlphaFold2 for protein structure prediction using the ColabFold Docker. This approach allows us to run AlphaFold2 locally on our machines or on a shared workstation, without the need for a high-performance computing cluster. We will cover the basics of running AlphaFold2, analyzing the results, and understanding the key concepts behind the predictions.

Throughout this tutorial, we will use small proteins or peptide dimers as examples due to the limited GPU memory available on typical workstations. For larger systems, we recommend using Google Colab with a GPU instance, which we will briefly discuss as an optional challenge.

## Before we start...

Please take into consideration the following indications about the text contained in this document:

**Bold text means that these files and/or this information is provided.**

*Italicized text means that this material will NOT be conducted during the workshop*

    fixed width text means you should type the command into your terminal

If you want to try making files that already exist (e.g., input files), write them to a different directory! (`mkdir my_dir`). Copy & pasting can sometimes lead to weird errors, so when in doubt try to type the commands instead.

## Setup

1. Ensure Docker is installed on your system. You can check on how to install docker in your computer at https://docs.docker.com/engine/install/

2. Pull the ColabFold Dockerr image:
      ```bash
      docker pull ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2
      ```

3. Enter the `1-structure_prediction` folder to run the tutorial:
   ```bash
   cd rosetta_workshop_2024/1-structure_prediction
   ```

4. Run the `download_weights.sh` script located in the `rosetta_workshop_2024` folder **(Note: This step has been already performed in the computer you are now using)** . This will download weights for AlphaFold2:
    ```bash
    #This step has been already performed in the computer you are now using
    bash ../download_weights.sh
    ```

## 1. Simple Structure Prediction

We will start with a simple example of a protein structure prediction using a short peptide sequence.

1. Create a file named `2M2Q.fasta` with the following content:
   ```
   >2M2Q
   GCPRILMRCKQDSDCLAGCVCGPNGFCG
   ```

      You can easily create this file using
      
   ```bash
   echo ">2M2Q" > 2M2Q.fasta
   echo "GCPRILMRCKQDSDCLAGCVCGPNGFCG" >> 2M2Q.fasta
    ```


2. Run AlphaFold2 by starting the ColabFold Docker container using the `run_docker.sh` script from the `input_files` folder. In brief, we are using this script for binding the folders that contain the AlphaFold2 weights that we just downloaded to their expected locations inside the ColabFold Docker image:
   ```bash
   bash input_files/run_docker.sh
   ```

3. Run the structure prediction for the `2M2Q.fasta` file as follows:
   ```bash
   colabfold_batch /work/2M2Q.fasta /work/output
   exit
   ```

   This command will run AlphaFold2 and generate predictions in the `output` directory.

4. Check the output printed by ColabFold:

   ```reranking models by 'plddt' metric
   rank_001_alphafold2_ptm_model_5_seed_000 pLDDT=94.6 pTM=0.479
   rank_002_alphafold2_ptm_model_3_seed_000 pLDDT=94.2 pTM=0.478
   rank_003_alphafold2_ptm_model_4_seed_000 pLDDT=92.6 pTM=0.456
   rank_004_alphafold2_ptm_model_1_seed_000 pLDDT=88.2 pTM=0.394
   rank_005_alphafold2_ptm_model_2_seed_000 pLDDT=87.2 pTM=0.385
   ```

   pLDDT corresponds to the predicted local distance difference test, a per-residue measure of local confidence. pLDDT ranges from 0 - 100, with higher values expected to be modelled to high accuracy.

   pTM corresponds to the predicted Template Modelling score for a superposition between the predicted structure and the hypothetical true structure. pTM ranges from 0 - 1, with higher values indicating that the predicted structure is similar to the true structure.

4. Analyze the results using PyMol or ChimeraX.

   For PyMol, open a new terminal and load your structures on PyMol as follows:
   ```bash
   conda activate RAI_workshop
   pymol output/2M2Q_unrelaxed_rank_*.pdb
   ```

   Then use the following commands on the PyMol command-line:
   ```bash
   allobjects = cmd.get_object_list('all')
   from itertools import combinations
   for pair in combinations(allobjects, 2): print(pair[0], pair[1], cmd.align(pair[0], pair[1], cycles=0, transform=1)[0])
   spectrum b, red_white_blue, minimum=0, maximum=100
   show sticks, resn CYS
   util.cbac resn CYS and not name CA
   ```

   *Are you more familiarized with Chimera than PyMol? Feel free to use Chimera instead*

5. Examine the structures and consider the following questions:
   - How consistent are the pLDDT values across the models?
   - Are there any regions with consistently low or high confidence?
   - Do you observe any disulfide bonds? Are they consistent across models?

## 2. Predicting Multimers

In this second case, we will use AlphaFold2 to model a dimeric complex.

1. Create a new input file `1FD4_dimer.fasta` with the sequence of human beta defensin-2 repeated twice, seperated by ":" :
   ```
   >1FD4
   GIGDPVTCLKSGAICHPVFCPRRYKQIGTCGLPGTKCCKKP:GIGDPVTCLKSGAICHPVFCPRRYKQIGTCGLPGTKCCKKP
   ```

2. Run AlphaFold2 in multimer mode. *Please note that we are using a low number of recycles (i.e. iterations of using the previous cycle's output as the new cycle's input to refine structure predictions) with* `--num-recycle 3`, *whereas a higher number of recycles might be ideal*:
   ```bash
   bash input_files/run_docker.sh
   colabfold_batch /work/1FD4_dimer.fasta /work/output --num-recycle 3
   exit
   ```

You might have noticed that now you have yet another confidence parameter, ipTM. This value measures the accuracy of the predicted relative positions of the subunits forming the protein-protein complex Again, the higher the ipTM, the better, with numbers ranging 0.6 - 0.8 being in a grey zone in which we are not sure if predictions are right or wrong.

As you can see from this example, the ipTM in recycle 0 is fairly bad, but dramatically improves upon recycling.

3. Analyze the results using PyMol or ChimeraX.

   For PyMol, open a new terminal and load your structures on PyMol as follows:

   ```bash
   conda activate RAI_workshop
   pymol output/1FD4_unrelaxed_rank_*.pdb input_files/1fd4.pdb
   ```

   Then use the following commands on the PyMol command-line:
   ```bash
   allobjects = cmd.get_object_list('all')
   from itertools import combinations
   for pair in combinations(allobjects, 2): print(pair[0], pair[1], cmd.align(pair[0]+" and chain A", pair[1]+" and chain A", cycles=0, transform=1)[0])
   set cartoon_color, cyan, 1FD4_* and chain A
   set cartoon_color, yellow, 1FD4_* and chain B
   set cartoon_color, tan, 1fd4
   hide cartoon, 1fd4 and chain C+D+E+F+G+H+I+J+K+L+M+N+O+P
   hide spheres
   hide nonbonded
   zoom 1FD4_*
   ```
   
   *Are you more familiarized with Chimera than PyMol? Feel free to use Chimera instead*

4. Consider the following questions:
   - How well does AlphaFold2 predict the dimeric interface?
   - Are there significant differences between the predicted models?
   - How does the best-ranking model compare to the experimental structure?

## 3. Predicting Alternative Conformations

In this final case, we will explore how to manipulate AlphaFold2 to predict alternative conformations of a protein. Note that this last case might take a while to run due to the size of the protein being tested.

1. Create a new input file `AGTR1.fasta` with the sequence of the Angiotensin II receptor type 1:
   ```
   >AGTR1
   MILNSSTEDGIKRIQDDCPKAGRHNYIFVMIPTLYSIIFVVGIFGNSLVVIVIYFYMKLK
   TVASVFLLNLALADLCFLLTLPLWAVYTAMEYRWPFGNYLCKIASASVSFNLYASVFLLT
   CLSIDRYLAIVHPMKSRLRRTMLVAKVTCIIIWLLAGLASLPAIIHRNVFFIENTNITVC
   AFHYESQNSTLPIGLGLTKNILGFLFPFLIILTSYTLIWKALKKAYEIQKNKPRNDDIFK
   IIMAIVLFFFFSWIPHQIFTFLDVLIQLGIIRDCRIADIVDTAMPITICIAYFNNCLNPL
   FYGFLGKKFKRYFLQLLKYIPPKAKSHSNLSTKMSTLSYRPSDNVSSSTKKPAPCFEVE
   ```

2. Run AlphaFold2 with reduced MSA depth and custom templates:
   ```bash
   bash input_files/run_docker.sh
   colabfold_batch /work/AGTR1.fasta /work/output --max-msa 48:96 --custom-template-path /work/input_files
   exit
   ```

3. Analyze the results using PyMol or ChimeraX.

   For PyMol, open a new terminal and load your structures on PyMol as follows:

   ```bash
   conda activate RAI_workshop
   pymol output/AGTR1_unrelaxed_rank_*.pdb input_files/4yay.pdb input_files/6do1.pdb
   ```

   Then use the following commands on the PyMol command-line:
   ```bash
   allobjects = cmd.get_object_list('all')
   from itertools import combinations
   for pair in combinations(allobjects, 2): print(pair[0], pair[1], cmd.align(pair[0]+" and chain A", pair[1]+" and chain A", cycles=0, transform=1)[0])
   set cartoon_color, AGTR1*, gray
   set cartoon_color, 4yay, red
   set cartoon_color, 6do1, green
   hide cartoon, chain B+C+D+E+F+G+H
   hide nonbonded
   hide spheres
   hide sticks
   zoom AGTR1*
   ```

   *Are you more familiarized with Chimera than PyMol? Feel free to use Chimera instead*

   Focus on transmembrane helix 6 (TM6) and compare its position in the predicted models to the reference structures.

4. Consider the following questions:
   - How do the predicted conformations compare to the active (6do1) and inactive (4yay) reference structures?
   - Does reducing the MSA depth and providing custom templates affect the predictions? *You can test this hypothesis by changing the* `--max-msa` *and* `--custom-template-path` *parameters*

## Conclusion

In this tutorial, we explored how to use AlphaFold2 via ColabFold Docker for various protein structure prediction tasks. We covered simple structure prediction, modeling protein complexes and manipulating predictions to explore alternative conformations. By using the ColabFold Docker, we were able to run these predictions locally without the need for a high-performance computing cluster.

Remember that while AlphaFold is a powerful tool, it is important to critically analyze the results and consider the limitations of the method. Always validate your predictions with experimental data when possible, and be cautious when interpreting results for proteins with limited sequence/structure information or complex structural features.

For larger systems or more extensive predictions, consider using Google Colab with a GPU instance, which provides more computational resources for running AlphaFold2.

## Optional Challenge

## 1. Using ColabFold on a GPU

The bigger the protein the longer it takes to run ColabFold on a CPU, huh? Well, thanks to the sponsorship from the National Laboratory for High Performance Computing [(NLHPC)](https://www.nlhpc.cl/), we have access to run ColabFold in their GPUs just for today.

1. Log in to the Leftraru cluster at NLHPC using the following command, changing the username to "studentN", where N is the result of adding 23 to the number you see in your current terminal for your workstation (e.g. if your computer has the username "dcc1" or "dcc01", your username will be "student24". We have a total of 17 accounts from 24-40)

   ```bash
   ssh -p 4603 studentN@leftraru.nlhpc.cl
   ```

   After that you will be requested to accept the fingerprint by typing `yes` and pressing Enter, and to enter the password, which is `rosetta2024`.

2. Go to the `colabfold` folder:

   ```bash
   cd colabfold
   ```

3. Run the different exercises from this tutorial by loading the following scripts onto the SLURM task manager queue:

   ```bash
   sbatch colabfold_ex1.sh
   sbatch colabfold_ex2.sh
   sbatch colabfold_ex3.sh
   ```

   Want to see what is inside the SLURM file?

   ```text
   #!/bin/bash
   #SBATCH --job-name=cfrun_ex1 #Name of your job
   #SBATCH --partition=v100 #The partition in the cluster that contains GPUs for running ColabFold
   #SBATCH --gres=gpu:1 #The number of gpus to use
   #SBATCH -w gn002 #The specific node in the partition to use
   #SBATCH --reservation=CursoRosetta #The cluster was reserved for this course
   #SBATCH -n 1 #The number of CPU processors
   #SBATCH -c 8 #The number of CPU cores
   #SBATCH --mem-per-cpu=4090 #The memory per CPU
   #SBATCH --output=af2_%j.out #Output file of the run
   #SBATCH --error=af2_%j.err #Output file in case of errors

   ml purge #Purging all modules
   ml fosscuda/2019b #Loading a CUDA-enabled module for GPU
   ml LocalColabFold/1.5.5 #Loading LocalColabFold

   colabfold_batch 2Q2M.fasta output_gpu #The script for running ColabFold
   ```

4. After your runs are done, the output files will be stored in the `output_gpu` folder. You can download this folder and all its content using the following command:
   ```bash
   scp -P 4603 -r studentN@leftraru.nlhpc.cl:~/colabfold/output_gpu .
   ```

   You will be requested to enter the password, which is `rosetta2024`.

   Once the files are downloaded, you can analyze them as we did at the beginning of the tutorial.

## 2. Using ColabFold on a GPU without access to a cluster

You might not have access to such high-performance computing capacities on a daily basis. The solution is to use ColabFold on Google Colab. You can find the ColabFold notebook at:
https://colab.research.google.com/github/sokrypton/ColabFold/blob/main/AlphaFold2.ipynb

When using Google Colab, you will have access to more powerful GPUs, allowing you to tackle larger and more complex prediction tasks. Compare the results you get from Colab with those from your local  ColabFold runs, and consider how the increased computational resources affect the quality and speed of your predictions.