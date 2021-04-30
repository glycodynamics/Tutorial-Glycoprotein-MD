# Molecular Dynamics of Glycoprotein

## Aimed at:
Anyone interested in learning  MD simulations for their research, in particular for studying glycoproteins or protein/glycan cimplexes.

### Requirements:
Basic knowledge the Linux command line molecular dynamics theory.

### Abstract:
The training workshop will introduce non-specialists to the use of MD simulations for modelling lycoproteins or protein/glycan cimplexes. Concepts and techniques of MD simulations will be explained through hands-on exercises. During the tutorial, each participant will perform MD simulation of sheep signalling glycoprotein (SPS-40) PDB ID: [2PI6](https://www.rcsb.org/structure/2PI6).

### Training Material
The tutorial workshop consists of a series of scripts to run the simulations and analysis of the outputs, accompanied by an informal lecture. The scripts can be run using the CCBRC training server, fucose.

Once you will login to fucose workstation open a Terminal (Click "New" top-right of the item list, and choose "Terminal" from the list). You will find the scripts and all other required workshop files there. Once you are finished, please copy all the data and "logout" from the server by pressing Ctrl +D.

All material was prepared by Sushil K. Mishra.

### Contents
In this tutorial workshop, you will learn how to perform MD simulation to model a glycoprotein and proten/g;cyan complex. You will model glycans or grycoproteins in [Glycam-Web](http://glycam.org/) and perform MD sumlation using [Amber20](https://ambermd.org/) simulation software from the AmberTools package. 


The sander and pmemd programmes are capable of the doing MD simulations required. 
AAMBER can accelerate molecular dynamics simulations using GPUs from nVIDIA. You will use program pmemd.cuda to perform MD on Nvidia RTX3080 GPU cards installed in Fucose computer. You can further use VMD to visualise the simulations on your local machine (after downloading the final files).

You will be simulating SPS-40 glycoprotein. Follwo these teps to perform MD.

#### 1.Login to Fucose: 
Use account information provided during the hands-on session to login into fucose computer

#### 1.Download PDB structure:
Download PDB strucutre of the SPS-40 from the Protein Data Bank [2PI6] (https://www.rcsb.org/structure/2PI6). This structre contains protein, N-glcyan actanched to it, crystal waters and some hetro atoms. We only require coordinates of the protein atoms to create our system for MD simulation. Use grep to extract protein part and create a file protein.pdb. use following commands to do all these steps:
```
mkdir MD-GLYCOPROTEIN/01.PREP
cd MD-GLYCOPROTEIN/01.PREP
wget https://files.rcsb.org/download/2PI6.pdb
grep "ATOM" 2PI6.pdb > protein.pdb

```
Copy protein.pdb file to your local computer by using scp (in Linux) or WinSCP (in windows). You can also perform all these steps mentioend above in your local computer.

#### 2.Add N-Glcyan to protein structure:

![image](https://user-images.githubusercontent.com/10772897/116744150-8a5b0280-a9bf-11eb-8be6-2aefd40aa756.png)

— Open [Glycam-Web](http://glycam.org/)

— Select  Glycoprotein Builder

— Step 1: Choose file protein.pdb, then click continue.

— Step 2: Change Disulfide Bonds, Histidine Protonation	and other options if needed. 

— Step 3: To attach glycan, select the oligosaccharide library → High Mannose Oligosaccharides →  Select apropriate N-glycan

— Step 4: Click on 'Add glycan to glycosylation sites'- selct residue number 39 N-linging section → Continue

— Step 3: Click on Options; Choose Solvate Structures to Yes, Choose the shape of the solvent box: Rectangular/Cubic and Size of the solvent buffer: 11 Angstrom → Save and Continue

— Step 3: Download current structure. It will take a couple of minutes to build requested structure.

— Download glycam.tar.gz into your locam computer 

— and copy glycam.tar.gz file to 01.PREP direcotry in fucose computer. 


#### 3. Equilibration of the solvated glycoprotein system:

```
cd MD-GLYCOPROTEIN/01.PREP
tar -xvf glycam.tar.gz
cp structure.parm7 ../02.EQUIL/
cp structure.rst7 ../02.EQUIL/
cd ../02.EQUIL/
```

Running equilibration:

```
export pmemd_bin="mpirun -np 12 pmemd.MPI"
export amber_bin=pmemd.cuda


#----exicution part----#
NUM_OF_SOLUTE_RESIDUES=`tail -3 ../01.PREP/structure.pdb | head -1 | awk '{print $5}'`
PEQUI_TOP=structure.parm7
PEQUI_CRD=structure.rst7


#--------- Exicution Part ------#
cd equil01
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil01.tin > equil01.in || exit 1
$pmemd_bin -O -i equil01.in -p ../$PEQUI_TOP -c ../$PEQUI_CRD -ref ../$PEQUI_CRD -o equil01.out -r equil01.rst7

cd ../equil02
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil02.tin > equil02.in || exit 1
$amber_bin -O -i equil02.in -p ../$PEQUI_TOP -c ../equil01/equil01.rst7 -ref ../$PEQUI_CRD -o equil02.out -r equil02.rst7 -x equil02.nc

cd ../equil03
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil03.tin > equil03.in || exit 1
$amber_bin -O -i equil03.in -p ../$PEQUI_TOP -c ../equil02/equil02.rst7 -ref ../$PEQUI_CRD -o equil03.out -r equil03.rst7 -x equil03.nc

cd ../equil04
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil04.tin > equil04.in || exit 1
$amber_bin -O -i equil04.in -p ../$PEQUI_TOP -c ../equil03/equil03.rst7 -ref ../equil03/equil03.rst7 -o equil04.out -r equil04.rst7 -x equil04.nc

cd ../equil05
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil05.tin > equil05.in || exit 1
$amber_bin -O -i equil05.in -p ../$PEQUI_TOP -c ../equil04/equil04.rst7 -ref ../equil04/equil04.rst7 -o equil05.out -r equil05.rst7 -x equil05.nc

cd ../equil06
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil06.tin > equil06.in || exit 1
$amber_bin -O -i equil06.in -p ../$PEQUI_TOP -c ../equil05/equil05.rst7 -ref ../equil05/equil05.rst7 -o equil06.out -r equil06.rst7 -x equil06.nc

cd ../equil07
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil07.tin > equil07.in || exit 1
$amber_bin -O -i equil07.in -p ../$PEQUI_TOP -c ../equil06/equil06.rst7 -ref ../equil06/equil06.rst7 -o equil07.out -r equil07.rst7 -x equil07.nc

cd ../equil08
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil08.tin > equil08.in || exit 1
$amber_bin -O -i equil08.in -p ../$PEQUI_TOP -c ../equil07/equil07.rst7 -ref ../equil07/equil07.rst7 -o equil08.out -r equil08.rst7 -x equil08.nc

cd ../equil09
sed -e "s/NSOLRES/$NUM_OF_SOLUTE_RESIDUES/g" < equil09.tin > equil09.in || exit 1
$amber_bin -O -i equil09.in -p ../$PEQUI_TOP -c ../equil08/equil08.rst7 -ref ../equil08/equil08.rst7 -o equil09.out -r equil09.rst7 -x equil09.nc

cd ../equil10
$amber_bin -O  -i equil10.in -p ../$PEQUI_TOP -c ../equil09/equil09.rst7 -o equil10.out -r equil10.rst7 -x equil10.nc

```

```
module load amber/20
./eq-CGpu.sh &

```


#### 3. Running MD:

Production run input file:
```
# prod.in
# prod at 300 K, constant pressure- 1ns
#

&cntrl
 imin=0,  nstlim=500000, dt=0.002,
 irest=1,  ntx=5, iwrap=0,
 ntpr=5000, ntwx=5000, ntwr=5000,
 ioutfm=0,
 ntf=1, ntb=2, cut=9.0, ntc=2,
 temp0=300.0, ntt=3, gamma_ln=2.0,
 ntp=1, pres0=1.0, taup=1.2,
 &end
```

Running MD Simulation:
```
#!/bin/bash
source /usr/local/amber20/amber.sh
export CUDA_VISIBLE_DEVICES=0

#run MD
pmemd.cuda -O -i prod.in -p structure.parm7 -c equil10.rst7 -o prod01.out -r prod01.rst7 -x prod01.traj

```


```
nvidia-smi 
Fri Apr 30 15:55:31 2021       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 455.23.04    Driver Version: 455.23.04    CUDA Version: 11.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  GeForce RTX 3080    Off  | 00000000:01:00.0  On |                  N/A |
| 48%   70C    P2   258W / 320W |    850MiB / 10012MiB |     95%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
|   1  GeForce RTX 3080    Off  | 00000000:21:00.0 Off |                  N/A |
|  0%   36C    P8    30W / 320W |      1MiB / 10018MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    0   N/A  N/A      3159      G   /usr/bin/X                        268MiB |
|    0   N/A  N/A     70607      G   /usr/bin/gnome-shell              109MiB |
|    0   N/A  N/A     81874      C   pmemd.cuda                        467MiB |
|    1   N/A  N/A      3159      G   /usr/bin/X                          0MiB |
|    1   N/A  N/A     70607      G   /usr/bin/gnome-shell                0MiB |
+-----------------------------------------------------------------------------+

```
#### 4. Visualization of MD trajectory:
— Download and Install VMD in your local computer [VMD](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD)
— 
—
—
—
—
—











### Acknowledgement: 
Parts of the text has been adompted from CCPBioSim, qm/mm workshop. Source 
