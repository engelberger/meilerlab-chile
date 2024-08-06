# Rosetta ML Docker Tutorial

## Introduction

In this tutorial, we will use three different machine learning (ML) based methods embedded in Rosetta to predict stabilizing mutations of a plastic degrading enzyme called Polyester Hydrolase Leipzig 7 (PHL7). We'll use ProteinMPNN, the Evolutionary Scale Modeling (ESM) protein language model family, and the masked inverse folding with sequence transfer (MIF-ST) model.

## Before we start...

Please take into consideration the following indications about the text contained in this document:

**Bold text means that these files and/or this information is provided.**

*Italicized text means that this material will NOT be conducted during the workshop*

    fixed width text means you should type the command into your terminal

If you want to try making files that already exist (e.g., input files), write them to a different directory! (`mkdir my_dir`). Copy & pasting can sometimes lead to weird errors, so when in doubt try to type the commands instead.

## Setup

1. Ensure Docker is installed on your system. You can check on how to install docker in your computer at https://docs.docker.com/engine/install/

2. Pull the Rosetta Docker image:
   ```bash
   docker pull rosettacommons/rosetta:ml
   ```

3. Enter the `rosetta_ml_tutorial` folder to run the tutorial:
   ```bash
   cd rosetta_workshop_2024_CHL/rosetta_ml_tutorial
   ```

4. Run the `download_weights.sh` script located in the `ìnput_files` folder **(Note: This step has been already performed in the computer you are now using)** . This will download weights for the ESM protein language model family (specifically, esm2_t30_150M_UR50D), and the MIF-ST model:
    ```bash
    #This step has been already performed in the computer you are now using
    bash input_files/download_weights.sh
    ```

5. Start the Docker container using the `run_docker.sh` script from the `input_files` folder. In brief, we are using this script for binding the folders that contain the weights that we just downloaded to their expected locations inside the Rosetta Docker image, and also binding a full local version of Rosetta and your current working directory to the work folder inside the Rosetta Docker image:
    ```bash
    bash input_files/run_docker.sh
    ```

## 1. Prepare the Input Structure

1. Download the PDB file:
   ```bash
   wget https://files.rcsb.org/download/8BRB.pdb
   ```

2. Clean the PDB from everything that is not protein. Be careful with the new numbering which is off by one, as the first residue in the PDB has no coordinates and gets removed by the `clean_pdb` script. Keep this in mind when comparing positions to literature later. Let's get chain A from 8BRB: depending on your workstation you may or may not have the main folder:
   ```bash
   python /rosetta_host/main/tools/protein_tools/scripts/clean_pdb.py 8BRB A
   ```
     ```bash
   python /rosetta_host/tools/protein_tools/scripts/clean_pdb.py 8BRB A
   ```

        ```bash
   python ../input_files/clean_pdb.py 8BRB A
   ```

3. Repack the input structure. Repacking is often necessary to remove small clashes identified by the score function that might be present in the crystal structure. For brevity, we only generated a single structure. For actual production runs, we recommend generating a number of output structures, by increasing the `-nstruct 1` option to e.g. `-nstruct 25`:
   ```bash
   relax.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 8BRB_A.pdb -nstruct 1 -ex1 -ex2 -constrain_relax_to_start_coords -out:suffix _relax -beta
   ```
    *It can also be useful to pre-generate more backbone conformational diversity prior to design. However, backbone conformational diversity will not be explored in this tutorial due to computational time constraints.*

4. At this point, you might be wondering what is `-beta`. This is the new Rosetta energy function in active development. You can find more information about the current energy function that is the standard of Rosetta (`ref2015`) and the current version under development at https://docs.rosettacommons.org/docs/latest/rosetta_basics/scoring/Scorefunction-History

## 2. Predict Amino Acid Probabilities

Next, we predict amino acid probabilities with ProteinMPNN, MIF-ST and ESM. While ProteinMPNN is a quite fast calculation, ESM inference takes longer depending on which parameter size model is used. Here we use a slightly smaller model with 8M parameters (`esm_t6_8M_UR50D`). If your setup can handle a larger model, feel free to use `esm2_t30_150M_UR50D` or even `esm2_t33_650M_UR50D`. The reason for the longer calculation time is: A) the larger parameter size; and B) that for ESM prediction each residue gets masked and predicted one by one.

1. Create `predict_probs.xml` **(this file is available in the `ìnput_files` folder)**:
   ```xml
   <ROSETTASCRIPTS>
     <SCOREFXNS>
       <ScoreFunction name="beta" weights="beta"/>
     </SCOREFXNS>    
     <RESIDUE_SELECTORS>
       <Chain name="res" chains="A" />
     </RESIDUE_SELECTORS>
     <SIMPLE_METRICS>
       ----------------- Define models to use -----------------------------
       <PerResidueEsmProbabilitiesMetric name="esm" residue_selector="res" model="esm2_t6_8M_UR50D" multirun="true"/>
       <ProteinMPNNProbabilitiesMetric name="mpnn" residue_selector="res"/>
       <MIFSTProbabilitiesMetric name="mifst" residue_selector="res" multirun="false" use_gpu="false"/>
     </SIMPLE_METRICS>
     <MOVERS>
        ----------------- Save probabilities -------------------------------
        <SaveProbabilitiesMetricMover name="save_esm" metric="esm" filename="esm_probs.weights"/>
        <SaveProbabilitiesMetricMover name="save_mpnn" metric="mpnn" filename="mpnn_probs.weights"/>
        <SaveProbabilitiesMetricMover name="save_mifst" metric="mifst" filename="mifst_probs.weights"/>
     </MOVERS>
     <PROTOCOLS>
       <Add mover_name="save_mifst"/>
       <Add mover_name="save_esm"/>
       <Add mover_name="save_mpnn"/>
     </PROTOCOLS>
   </ROSETTASCRIPTS>
    ```

2. Run the prediction:
   ```bash
   rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 8BRB_A_relax_0001.pdb -parser:protocol ../input_files/predict_probs.xml -auto_download -beta \
     -out:file:score_only score.sc
   ```
3.  The saved probabilities are now stored in your working directory as `esm_probs.weights`, `mifst_probs.weights` and `mpnn_probs.weights`. Each files contains three columns: the residue position, the residue type and the calculated probabilities. *Feel free to examine them using `gedit`, `vi`, `paste`, or your system's text editor*.

## 3. Analyze Current Probabilities

Now we will analyze and compare the predictions made by ProteinMPNN, ESM and MIF-ST. First, we will analyze the probabilities of the wild type amino acids, which will be between 0 (0%) and 1 (100%). To do so we load either prediction, take out just the probability for the current amino acid and then store it in the b factor column of the output PDB (the first column from the right). This allows us to easily visualize the scores in PyMol.

1. Create `current_probs.xml` **(this file is available in the `ìnput_files` folder)**:
   ```xml
   <ROSETTASCRIPTS>
     <SCOREFXNS>
       <ScoreFunction name="beta" weights="beta"/>
     </SCOREFXNS>
     <RESIDUE_SELECTORS>
       <Chain name="res" chains="A" />
     </RESIDUE_SELECTORS>
     <SIMPLE_METRICS>
       <LoadedProbabilitiesMetric name="prediction" filename="%%filename%%"/>
       <CurrentProbabilityMetric name="current" metric="prediction" custom_type="score"/>
     </SIMPLE_METRICS>
     <FILTERS>
     </FILTERS>
     <MOVERS>
       <RunSimpleMetrics name="run" metrics="current" metric_to_bfactor="score"/>
     </MOVERS>
     <PROTOCOLS>
       <Add mover_name="run"/>
     </PROTOCOLS>
   </ROSETTASCRIPTS>
   ```

2. Run for each prediction:
   ```bash
   for model in mpnn esm mifst; do
     rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
       -s 8BRB_A_relax_0001.pdb -parser:protocol ../input_files/current_probs.xml -beta \
       -out:suffix _${model}_probs -parser:script_vars filename=${model}_probs.weights
   done
   ```

3. Open a new terminal and load your structures on PyMol as follows:
    ```bash
    conda activate RAI_workshop
    pymol 8BRB_A_relax_0001_*_probs_0001.pdb
    ```

    Then use the following commands on the PyMol command-line:
    ```bash
    spectrum b, red_white_blue, minimum=0, maximum=1
    select binding, resi 63+64+68+131+155
    select catal, resi 130+176+208
    show sticks, binding
    show sticks, catal
    load 8BRB.pdb
    remove solvent
    remove 8BRB and chain B
    zoom
    set seq_view, 1
    ```

    The PyMol structures contain the ProteinMPNN, ESM and MIF-ST do not have any direct information on the ligand, the product binding site or the function of PHL7, however, you will realize that ESM and MIF-ST predict the involved binding site residues as more likely as ProteinMPNN. This comes down to the way these two models were trained: while ESM relies heavily on evolutionary information from sequences, ProteinMPNN relies more on the actual provided input structure. Interestingly, all models predict that the mutation that makes PHL7 inactive (S130A in our numbering) is unlikely. This shows that while ESM/MIF-ST might have captured more evolutionary information, ProteinMPNN definitely has learned how a catalytic triad should look (residues D176 and H208 in our numbering).

    *Are you more familiarized with Chimera than PyMol? Feel free to use Chimera instead*

## 4. Find Best Mutations

Now we will use the information from the different predictions to find some useful mutations. First, we will predict the most impactful single-point mutations (useful if you are interested in just doing site-directed mutagenesis and do not want to change too much of your protein). For simplicity, we will first average the predictions made by ProteinMPNN, ESM and MIF-ST.

1. Create `best_mutations.xml` **(this file is available in the `ìnput_files` folder)**:
   ```xml
   <ROSETTASCRIPTS>
     <SCOREFXNS>
       <ScoreFunction name="beta" weights="beta"/>
     </SCOREFXNS>
     <RESIDUE_SELECTORS>
       <Chain name="res" chains="A" />
     </RESIDUE_SELECTORS>
     <SIMPLE_METRICS>
       ----------------- Load Probabilities -----------------------------
       <LoadedProbabilitiesMetric name="mpnn" filename="mpnn_probs.weights" custom_type="mpnn"/>
       <LoadedProbabilitiesMetric name="esm" filename="esm_probs.weights" custom_type="esm"/>
       <LoadedProbabilitiesMetric name="mifst" filename="mifst_probs.weights" custom_type="mifst"/>
       ----------------- Average the probabilities ------------------------
       <AverageProbabilitiesMetric name="avg" metrics="mpnn,esm,mifst"/>
       ----------------- Analyze predictions -------
       <BestMutationsFromProbabilitiesMetric name="avg_mutations" metric="avg" max_mutations="10" custom_type="avg"/>
     </SIMPLE_METRICS>
     <FILTERS>
     </FILTERS>
     <MOVERS>
       <RunSimpleMetrics name="analysis" metrics="avg_mutations"/>
       <SaveProbabilitiesMetricMover name="save_avg" metric="avg" filename="average_probs" filetype="both"/>
     </MOVERS>
     <PROTOCOLS>
       <Add mover="analysis"/>
       <Add mover="save_avg"/>
     </PROTOCOLS>
   </ROSETTASCRIPTS>
   ```

2. Run the command:
   ```bash
   rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 8BRB_A_relax_0001.pdb -parser:protocol ../input_files/best_mutations.xml -beta \
     -out:file:score_only best_mutations.sc
   ```

3. You can now check the best mutations on your screen by running:
    ```bash
    tail -n +2 best_mutations.sc | tr -s " " | tr ' ' '\n' | pr -2ts' '
    ```

    The mutation with the highest delta_probability is A130S, which is in fact the mutation that restores the activity of PHL7, highlighting the evolutionary/structural information learned by ESM/ProteinMPNN. Another interesting proposed mutation is E147K. E147 and D232 are part of an metal ion binding site in PHL7.

## 5. Sample New Sequences

Now we will use the information stored in the probabilities to create some new enzyme sequences using the `SampleSequenceFromProbabilities` mover. Due to time constraints we will just create 3 designs. You can control the diversity with the `pos_temp` and `aa_temp` option, where values higher than 1.0 lead to more diversity and lower than 1.0 to less diversity. Additionally, you can choose the amount of mutations you would like via the `max_mutations` option.

Lastly, we score the generated proteins using the Rosetta energy function and another round of ProteinMPNN/ESM/MIF-ST predictions via the `PseudoPerplexityMetric`. The pseudo-perplexity calculates a single score (where lower is better, min=1) from the predicted probabilities for each ProteinMPNN, MIF-ST and ESM.

*For time reasons the MIF-ST pseudo-perplexity calculation is commented out in the XML, feel free to enable it depending on your time/computational constraints*

1. Create `sample_sequences.xml` **(this file is available in the `ìnput_files` folder)**:
   ```xml
   <ROSETTASCRIPTS>
     <SCOREFXNS>
       <ScoreFunction name="beta" weights="beta"/>
     </SCOREFXNS>
     <RESIDUE_SELECTORS>
       <Chain name="res" chains="A" />
     </RESIDUE_SELECTORS>
     <SIMPLE_METRICS>
       ----------------- Load the probabilities ------------------------
       <LoadedProbabilitiesMetric name="avg" filename="average_probs.weights" custom_type="avg"/>
       ----------------- score with MPNN predictions ----------------------
       <ProteinMPNNProbabilitiesMetric name="score_mpnn" residue_selector="res"/>
       <PerResidueEsmProbabilitiesMetric name="score_esm" residue_selector="res" model="esm2_t6_8M_UR50D"/>
       <MIFSTProbabilitiesMetric name="score_mifst" residue_selector="res" multirun="false" use_gpu="false"/>
       <PseudoPerplexityMetric name="mpnn_perplexity" metric="score_mpnn" custom_type="mpnn"/>
       <PseudoPerplexityMetric name="esm_perplexity" metric="score_esm" custom_type="esm"/>
       <PseudoPerplexityMetric name="mifst_perplexity" metric="score_mifst" custom_type="mifst"/>
     </SIMPLE_METRICS>
     <FILTERS>
     </FILTERS>
     <MOVERS>
       <SampleSequenceFromProbabilities name="sample" metric="avg" pos_temp="1.5" aa_temp="0.3" prob_cutoff="0.0001" delta_prob_cutoff="-0.3" max_mutations="40" use_cached_data="true"/>
       <FastRelax name="relax" relaxscript="MonomerRelax2019" scorefxn="beta">
       <MoveMap name="rest" bb="true" chi="true"/>
       </FastRelax>
       <RunSimpleMetrics name="run_perplexity" metrics="mpnn_perplexity,esm_perplexity"/>
       RunSimpleMetrics name="run_perplexity_mifst" metrics="mifst_perplexity"/>
     </MOVERS>
     <PROTOCOLS>
       <Add mover_name="sample"/>
       <Add mover_name="relax"/>
       <Add mover_name="run_perplexity"/>
       Add mover_name="run_perplexity_mifst"/>
     </PROTOCOLS>
     <OUTPUT scorefxn="beta"/>
   </ROSETTASCRIPTS>
   ```

2. Run the command:
   ```bash
   rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 8BRB_A_relax_0001.pdb -parser:protocol ../input_files/sample_sequences.xml -beta \
     -out:suffix _design -nstruct 3
   ```

3. Take a look at the output structures (e.g. in PyMol). Which mutations got introduced and where are they? How do their Rosetta total_scores compare to the wild-type (take a look at the `score_design.sc` scorefile). Are better total scores also reflected in a better ESM or ProteinMPNN pseudo-perplexity score? The following commands can help you out in this task:
   ```bash
   awk '{print $NF, $2}' score_relax.sc
   awk '{print $NF, $2, $4, $26}' score_design.sc
   ```

## 6. Constrain Energy Function

We can also restrain ("constrain" in Rosetta jargon) the energy function of Rosetta with our predictions and then run any protocol (like design) using the modified energy function. We can also turn off amino acids below a custom probability threshold for design, which drastically limits the sequence space we have to search. Lastly, we can also eliminate specific residues that are not desired to include in our designs, such as cysteines. 

We will use the saved probabilities (in PSSM formatting) together with the `FavorSequenceProfileMover` to constrain the energy function. Besides that, we will use the `RestrictAAsFromProbabilities` task operation to turn off any amino acids that are less likely than the wild type. *Feel free to play around with the probability cutoffs*. Finally, we will also use the `PackRotamersMover` (fixBB) with a `resfile` that will allow all amino acids to be included except for cysteines. *You can also modify this to keep the active site residues fixed.*

1. Create `constrain_energy.xml` (this file is available in the `ìnput_files` folder):
   ```xml
   <ROSETTASCRIPTS>
     <RESIDUE_SELECTORS>
       <Chain name="chain_A" chains="A" />
     </RESIDUE_SELECTORS>
     <SCOREFXNS>
       <ScoreFunction name="beta" weights="beta"/>
       <ScoreFunction name="beta_cst" weights="beta">
         <Reweight scoretype="res_type_constraint" weight="1.0"/>
       </ScoreFunction>
     </SCOREFXNS>
     <SIMPLE_METRICS>
       <LoadedProbabilitiesMetric name="loaded_probs" filename="average_probs.weights"/>
       <SequenceRecoveryMetric name="sequence_recovery" residue_selector="chain_A" reference_name="native_pose" />
       <ProteinMPNNProbabilitiesMetric name="score_mpnn" residue_selector="chain_A"/>
       <PseudoPerplexityMetric name="mpnn_perplexity" metric="score_mpnn" custom_type="mpnn"/>
     </SIMPLE_METRICS>
     <TASKOPERATIONS>
       <InitializeFromCommandline name="ifcl"/>
       <ReadResfile name="rrf" filename="input_files/resfile.resfile"/>
       <RestrictAAsFromProbabilities name="restrict_to_probs" metric="loaded_probs" prob_cutoff="0.0001" delta_prob_cutoff="0.0" use_cached_data="true"/>
     </TASKOPERATIONS>
     <MOVERS>
       <SavePoseMover name="save_native" reference_name="native_pose"/>
       <RunSimpleMetrics name="load" metrics="loaded_probs"/>
       <RunSimpleMetrics name="run_seqrec" metrics="sequence_recovery,mpnn_perplexity"/>
       <FavorSequenceProfile name="favor" scaling="global" weight="15" pssm="average_probs.pssm" scorefxns="beta_cst" chain="1"/>
       <PackRotamersMover name="design" scorefxn="beta_cst" task_operations="ifcl,rrf,restrict_to_probs" />
     </MOVERS>
     <FILTERS>
     </FILTERS>
     <APPLY_TO_POSE>
     </APPLY_TO_POSE>
     <PROTOCOLS>
       <Add mover="save_native"/>
       <Add mover="load"/>
       <Add mover="favor"/>
       <Add mover="design"/>
       <Add mover="run_seqrec"/>
     </PROTOCOLS>
     <OUTPUT scorefxn="beta" />
   </ROSETTASCRIPTS>
   ```

2. Run the command:
   ```bash
   rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 8BRB_A_relax_0001.pdb -parser:protocol ../input_files/constrain_energy.xml -beta -ex1 \
     -ex2aro -nstruct 20 -out:suffix _constraint_design
   ```

3. The results in the scorefile `score_constraint_design.sc` include the Rosetta scores, the sequence recovery (% of positions that are identical to the wild type) and again the pseudo-perplexity score using ProteinMPNN. How much of the sequence got changed? Analyze the results as follows:
   ```bash
   awk '{print $NF, $2, $16, $22}' score_constraint_design.sc
   ```

    For the constraint designs we used the `PackRotamersMover` and therefore we did not change the backbone of our protein. *Try to modify the XML file to either introduce a `FastRelaxMover` after the design or directly replace the* `PackRotamersMover` *with a* `FastRelaxMover` *that has the same task operations (and therefore runs design). Take a look at the example from our run before* `input_files/sample_sequences.xml` *and the* [documentation here](https://docs.rosettacommons.org/docs/latest/scripting_documentation/RosettaScripts/Movers/movers_pages/FastRelaxMover) *to get started.* 

    *Besides that, play around with the probability thresholds of the* `RestrictAAsFromProbabilities`*, how does that influence the sequence recovery of the designed sequences?*

That's it for now! If you are further interested take a look [at the documentation here](https://docs.rosettacommons.org/docs/latest/scripting_documentation/RosettaScripts/composite_protocols/Working-with-PerResidueProbabilitiesMetrics) for the RosettaScripts elements we worked with today.

# Optional challenge
## 1. Design a protein-protein interface

From the previous example, we saw that models like MIF-ST and ESM, which are trained on large sequence datasets, capture evolutionary properties even in the absence of direct information. Therefore, we might prefer to use ProteinMPNN to sample mutations for stability/solubility objectives and ESM/MIF-ST to sample mutations that affect enzymatic activity. But what happens if we have a design objective that is not in line with the natural function of a protein?

Another common design objective is to create/increase binding affinity of one protein to another protein target. Thus, we will take a look at how ProteinMPNN predicts the likelihood of residues laying in the interface of a hetero-dimer compared to MIF-ST. To do so we will use a structure of the nucleosome core particle **provided as 1KX5_chAB.pdb in the `input_files` folder**.

A common way to score interfaces in Rosetta is to calculate the interface score ("dG_separated") by substracting the total_score of the separated state from the total_score of the complexed state. This can be done with the `InterfaceAnalyzerMover` ([documented here](https://docs.rosettacommons.org/docs/latest/scripting_documentation/RosettaScripts/Movers/movers_pages/analysis/InterfaceAnalyzerMover)), which also can calculate the delta for an arbitrary `RealMetric`. We will use this mover to not only calculate the Rosetta interface score but also the difference in ProteinMPNN/MIF-ST pseudo-perplexity between the complexed and separated states. This way we can analyze if the predicted probabilities change depending on whether we provide a protein complex or single proteins to the models.

1. Copy the input PDB file of the nucleosome core particle into your working directory
    ```bash
    cp input_files/1KX5_chAB.pdb .
    ```

  *Alternatively you could download the PDB of the nucleosome core particle, relax it and repack it using Rosetta as you did for PHL7.
   ```bash
   wget https://files.rcsb.org/download/1KX5.pdb


2. Relax and repack the structure
    ```bash
    python /rosetta_host/tools/protein_tools/scripts/clean_pdb.py 1KX5.pdb AB

    relax.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
    -s 1KX5_AB.pdb -nstruct 1 -ex1 -ex2 -constrain_relax_to_start_coords -out:suffix _relax -beta
    ```

3. Create `IFA_perplexity.xml` (this file is available in the `ìnput_files` folder):
   ```xml
   <ROSETTASCRIPTS>
     <SCOREFXNS>
        <ScoreFunction name="ref2015" weights="ref2015"/>
     </SCOREFXNS>
     <RESIDUE_SELECTORS>
        <Chain name="all" chains="1,2"/>
     </RESIDUE_SELECTORS>
     <SIMPLE_METRICS>
        <ProteinMPNNProbabilitiesMetric name="mpnn" residue_selector="all"/>
        <MIFSTProbabilitiesMetric name="mifst" residue_selector="all" feature_selector="all" multirun="false" use_gpu="false"/>
        <PseudoPerplexityMetric name="perplexity_mifst" metric="mifst" custom_type="MIFST"/>
        <PseudoPerplexityMetric name="perplexity_mpnn" metric="mpnn" custom_type="MPNN"/>
     </SIMPLE_METRICS>
     <FILTERS>
     </FILTERS>
     <MOVERS>
        <InterfaceAnalyzerMover name="intana" scorefxn="ref2015" pack_separated="true"
        interface_sc="false" use_jobname="false" interface="A_B" tracer="false" delta_metrics="perplexity_mpnn,perplexity_mifst"/>
     </MOVERS>
     <PROTOCOLS>
        <Add mover="intana"/>
     </PROTOCOLS>
     <OUTPUT scorefxn="ref2015"/>
   </ROSETTASCRIPTS>
   ```

3. Run the command:
   ```bash
   rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 1KX5_AB_relax_0001.pdb -parser:protocol input_files/IFA_perplexity.xml -beta \
     -out:file:score_only score_interface.sc
   ```

4. Analyze the results:
   ```bash
   awk '{print $NF,$2,$6,$12,$11}' score_interface.sc
   ```

## 8. Analyze Interface Residues

1. Create `current_probs_mifst_dimer.xml` (this file is available in the `ìnput_files` folder):
   ```xml
   <ROSETTASCRIPTS>
       <SCOREFNXS>
         <ScoreFunction name="ref2015" weights="ref2015"/>
       </SCOREFNXS>
       <RESIDUE_SELECTORS>
         <Chain name="res" chains="1,2" />
       </RESIDUE_SELECTORS>
       <SIMPLE_METRICS>
         <MIFSTProbabilitiesMetric name="mifst" residue_selector="res" multirun="false" use_gpu="false"/>
         <CurrentProbabilityMetric name="current" metric="mifst" custom_type="score"/>
       </SIMPLE_METRICS>
       <FILTERS>
       </FILTERS>
       <MOVERS>
         <RunSimpleMetrics name="run" metrics="current" metric_to_bfactor="score"/>
       </MOVERS>
       <PROTOCOLS>
         <Add mover_name="run"/>
       </PROTOCOLS>
   </ROSETTASCRIPTS>
    ```

2. Run the command:
   ```bash
   rosetta_scripts.cxx11threadmpipytorchserializationtensorflow.linuxgccrelease \
     -s 1KX5_AB_relax_0001.pdb -parser:protocol input_files/current_probs_mifst_dimer.xml \
     -out:suffix _mifst_probs
   ```

3. Analyze the results using PyMOL (outside the Docker container):
   ```
   pymol
   load 1KX5_chAB_mifst_probs_0001.pdb
   spectrum b, red_white_blue, minimum=0, maximum=1
   ```

## Conclusion

This tutorial has guided you through using machine learning methods in Rosetta to predict stabilizing mutations, analyze protein interfaces, and explore the differences between various ML models in protein design. Remember to exit the Docker container when you're finished:

```bash
exit
```

For further information, refer to the [Rosetta documentation](https://docs.rosettacommons.org/docs/latest/scripting_documentation/RosettaScripts/composite_protocols/Working-with-PerResidueProbabilitiesMetrics).