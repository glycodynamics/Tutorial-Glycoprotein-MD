# Molecular Dynamics of Glycoproteins
      Sushil Mishra, 04/25/2021
      Last updated on 05/04/2021
      ** Version 1.0**
## Aimed at:
Anyone interested in learning  MD simulations for their research, in particular for studying glycoproteins or protein/glycan complexes.

### Requirements:
Basic knowledge of the Linux command line and basics of the theory behind molecular dynamics simulations.

### Abstract:
The training workshop will introduce non-specialists to the use of MD simulations for modeling glycoproteins or protein/glycan complexes. Concepts and techniques of MD simulations will be explained through hands-on exercises. During the tutorial, each participant will perform an MD simulation of sheep signaling glycoprotein (SPS-40) PDB ID: [2PI6](https://www.rcsb.org/structure/2PI6).

### Training Material
The tutorial workshop consists of a series of scripts to run the simulations and analysis of the outputs, accompanied by an informal lecture. The scripts can be run using the CCBRC training server, fucose.

Once you are logged in to the fucose workstation, open a Terminal (Click "New" top-right of the item list, and choose "Terminal" from the list). You will find the scripts and all other required workshop files there. Once you are finished, please copy all the data and "log out" from the server by pressing Ctrl +D.

### Contents
In this tutorial workshop, you will learn how to perform MD simulation to model a glycoprotein and protein/glycan complex. You will model glycans or glycoproteins in [Glycam-Web](http://glycam.org/) and perform MD simulation using [Amber20](https://ambermd.org/) simulation software from the AmberTools package. 

The sander and pmemd programs are capable of doing MD simulations required. AMBER can accelerate molecular dynamics simulations using GPUs from NVIDIA. You will use the program pmemd.cuda to perform MD on Nvidia RTX3080 GPU cards installed in the Fucose computer. You can further use VMD to visualize the simulations on your local machine (after downloading the final files).

You will be simulating SPS-40 glycoprotein. Follow these steps to perform MD.

#### 1.Login to Fucose: 
Use account information provided during the hands-on session to login into fucose computer.

#### 1.Download PDB structure:
Download PDB structure of the SPS-40 from the Protein Data Bank [2PI6] (https://www.rcsb.org/structure/2PI6). This structure contains protein, N-glycan attached to it, crystal waters, and some heteroatoms. We only require coordinates of the protein atoms to create our system for MD simulation. You can use grep to extract the protein part and create a file protein.pdb. However, Glycam-web can read pdb file and it will remove all the heetero atoms itself. 

#### 2.Add N-Glcyan to protein structure:

![image](https://user-images.githubusercontent.com/10772897/116744150-8a5b0280-a9bf-11eb-8be6-2aefd40aa756.png)

— Open [Glycam-Web](http://glycam.org/)

— Select  Glycoprotein Builder

— Step 1: Choose file 2pi6.pdb, then click continue.

— Step 2: Change Disulfide Bonds, Histidine Protonation, and other options if needed. 

— Step 3: To attach glycan, select the oligosaccharide library → High Mannose Oligosaccharides →  Select appropriate N-glycan

— Step 4: Click on 'Add glycan to glycosylation sites'- select residue number 39 N-linking section → Continue

— Step 3: Click on Options; Choose Solvate Structures to Yes, Choose the shape of the solvent box: Rectangular/Cubic and Size of the solvent buffer: 11 Angstrom → Save and Continue

— Step 3: Download current structure. It will take a couple of minutes to build the requested structure.

— Download glycam.tar.gz into your local computer. 

— Unzip glycam.tar.gz into your local computer and visualize structure_AMBER.pdb file in VMD or PyMOL. Make sure glycan is attached to apropriate Asn and there is no bonds missing.  

— Finally you can copy glycam.tar.gz file to ~/tutorial/01.PREP directory in fucose computer. For your convenience, this file has been already copied to this directory.

#### 3. Equilibration of the solvated glycoprotein system:
Connect to focuse compuer:
```
ssh -X guestXX@fucose.pharmacy.olemiss.edu
```
Use the login credentials provided to you. Once conected go to ~/MD-GLYCOPROTEIN/01.PREP direcotry, unzip glycam.tar.gz archive and copy structure.parm7 & structure.parm7 files to ~/MD-GLYCOPROTEIN/02.EQUIL directory. These two files are needed to run MD simulation. Use following commands to do these tasks.
```
cd ~/MD-GLYCOPROTEIN/01.PREP
tar -xvf glycam.tar.gz
cp structure.parm7 ../02.EQUIL/
cp structure.rst7 ../02.EQUIL/
cd ../02.EQUIL/
```
Now you are inside the equilibration directory that contains the following files:
```
equil01 equil03 equil05 equil07 equil09 run-eq-CGpu.sh  structure.rst7
equil02 equil04 equil06 equil08 equil10 structure.parm7
```
directories equil01 to equil10 contain input files for a 10 step MD equilibration protocol. File run-eq-CGpu.sh has commands to run these 10 steps.
If your guest ID is an even number, use   CUDA_VISIBLE_DEVICES=0 and if it is an odd number use CUDA_VISIBLE_DEVICES=0
Running equilibration: 

```
export CUDA_VISIBLE_DEVICES=0
module load amber/20
./eq-CGpu.sh &
```
This calculation may take 20-30 minutes. Therefore try to understand the content of eq-CGpu.sh (see described below) in the mean-time: 
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

Once the equilibration is completed, chnage directory to 03.PROD:
```
cd ../03.PROD
```


#### 3. Running MD:
Now we will use the last frame from the equilibration to start the MD simulation. This equilibrated structure file is inside equil10 and named "equil10.rst7". This file will be used as starting frame of MD simulation. Copy equil10.rst7 and structure.parm7 to 03.PROD directory for runing MD.
```
cp ../02.EQUIL/equil10/equil10.rst7 .
cp ../01.PREP/structure.parm7 .
```
For the the purpose of this tutorial, we will be runing a short 1 nanosecond MD simulation at NPT. These valies have been placed in prod.in file, which is MD paramataer intut file. Production run input file has follwoing values:
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
imin=2 : no minization

nstlim=500000, dt=0.002: Run 500000 steps with 2fs time step

ntpr=5000, ntwx=5000, ntwr=5000: Write energies, trajectory and restart file every 5000 steps

ioutfm=0 : Write trajectory in Amber trajectory format. Use 1 for binary format

ntf=1, : Force calculation, complete interaction is calculated (default)

ntb=2, : Periodic boundaries are imposed, constant pressure

cut=9.0, : Non-bonded interaction cutoff distance

ntc=2, : Bonds involving hydrogen are constrained

temp0=300.0, ntt=3, gamma_ln=2.0: Temprature langevin thermostat to maintain a temprature of 300 K 

 ntp=1, pres0=1.0, taup=1.2: Pressure control 
 

The export CUDA_VISIBLE_DEVICES=0 line tells the computer to run on the GPU designated 0. You will likely have to change this to run on a GPU that is open on your computer. You can see which GPUs are open with this command:
```
nvidia-smi 
```
Which will output this information.
```
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
On this computer, there are two RTX3080 GPUs (0, 1). Their respective availability is shown on the right (GUP-Util). Here, GPUs 0 is 95% utilized, hence unavailable, but GPU 1 is free. So, we want to tell the computer to run our job on GPU 1 by setting CUDA_VISIBLE_DEVICES variable as following:
```
export CUDA_VISIBLE_DEVICES=1
```

Running MD Simulation:

```
nohup ./run_MD.sh &
```
Below is the command to run MD in run_MD.sh file and meaning of these flags.

```
pmemd.cuda -O -i prod.in -p structure.parm7 -c equil10.rst7 -o prod01.out -r prod01.rst7 -x prod01.traj

-O   Overwrite output files
-i   MD input file (prod.in)
-p   topology file (structure.parm7)
-c   the starting coordinate file (equil10.rst7)
-o   output file (prod01.out), which is where all the thermodynamic information for the production run will be output.
-r   restart file that output coordinates after each ntwr step of the simulation.
-x   file with positions of all atoms over the course of a simulation saved in a trajectory file (prod01.nc)
```


This will make the job run on the open GPU 1. The last line is what runs the simulation using pmemd.cuda (the GPU version). The following flags are used:


#### 4. Verify that your job is running:
```
nvidia-smi
```
You should see that the percentage of the GPU you specified increased to a percentage near 100%. You can also see information on your job by using the "top" command:
```
top
```
This will show you the PID (first column), who is running the job (second column), and what kind of job it is (last column), which should be pmemd.cuda for you. The "top" screen will be automatically updated in real-time. To exit back to the command line, type the "q" key on your keyboard.

If you need to kill your job for some reason (like you ran it on a busy GPU), then you can kill the job by typing:
```
kill -9 PID
```
If you don't know which PID corresponds to which job you need to kill, you can get the path of the directory that the job was run in by using this command:
```
pwdx PID
```
Note that you should only run one MD job in a directory at a time. Otherwise, things could get messy and you might overwrite some files.

#### 5. Monitor the progess of MD.
Running the script will make a file called "mdinfo". This is where you get information on how many steps have been completed, how many nanoseconds you can run per day with this system, and how much time is left before your specific job is finished.
```
 NSTEP =    85000   TIME(PS) =    3060.000  TEMP(K) =   301.27  PRESS =   223.6
 Etot   =   -116937.4902  EKtot   =     30819.1191  EPtot      =   -147756.6094
 BOND   =      1753.2873  ANGLE   =      2992.6234  DIHED      =      4584.2756
 1-4 NB =      2802.0438  1-4 EEL =     14983.5433  VDWAALS    =     17397.1077
 EELEC  =   -192269.4905  EHBOND  =         0.0000  RESTRAINT  =         0.0000
 EKCMT  =     13291.6373  VIRIAL  =     10885.8482  VOLUME     =    498424.5945
                                                    Density    =         1.0230
 ------------------------------------------------------------------------------
| Current Timing Info
| -------------------
| Total steps:    500000 | Completed:     85000 ( 17.0%) | Remaining:    415000
|
| Average timings for last   80000 steps:
|     Elapsed(s) =      63.52 Per Step(ms) =       0.79
|         ns/day =     217.64   seconds/ns =     396.98
|
| Average timings for all steps:
|     Elapsed(s) =      67.42 Per Step(ms) =       0.79
|         ns/day =     217.84   seconds/ns =     396.62
|
|
| Estimated time remaining:       5.5 minutes.
 ------------------------------------------------------------------------------
```

Running this script will also make a file called "nohup.out." This is where all of the errors are output. So, if you run a script and the job dies right away, you can check nohup.out for information on the error that occurred. Usually, these are syntax errors. With every nohup job that is run, nohup.out is written to with any errors for that job.

```
[sushil@idose 03.PROD]$ cat nohup.out 
Note: The following floating-point exceptions are signalling: IEEE_UNDERFLOW_FLAG IEEE_DENORMAL
```

The only warning is expected, and should not themselves be of concern. Underflows of "IEEE_UNDERFLOW_FLAG IEEE_DENORMAL" is the result of an expression that exceeds the precision of the variable being assigned the value. The underflow error is typically inconsequential and should have no impact on the results of the simulation. It can be ignored if pmemd.cuda tests did not show anything of concern shows up about the GPUs

Wait for the job to finish. It should take around 30 minutes hours (see mdinfo file to find out how much time it needs to complete). 

#### 6. Postprocess and analyze the trajectory:

Run cpptraj to postprocess trajecotry file (prod01.traj).

Now copy all the data back to your local machine using ssh (following) or WinSCP. If you have a Mac or Linux, open the terminal and run the following command to copy the data from the source (guestXX@fucose.pharmacy.olemiss.edu:~/*) to your desktop.
```
scp -r guestXX@fucose.pharmacy.olemiss.edu:~/* ~/Desktop/

```

#### 7. Visualization of MD trajectory:
— Download and Install VMD in your local computer [VMD](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD)

— Download Symbol Nomenclature For Glycan (SNFG) representation for glycans [SNFG](http://glycam.org/docs/othertoolsservice/2016/06/03/3d-symbol-nomenclature-for-glycans-3d-snfg/)

— Move the file to either your home directory, or the location where the VMD software is installed, and unzip the file.

— Now, open VMD

— Load a file containing a glycan into VMD (structure.parm7)

— Load trajectory file (prod01.traj) by selecting "Amber trajecotry file with periodic box)

— Go to graphics > representation > and change the representation of molecule as you wish to.

— Play MD and visualize trajectory

— Ask for help and an instructure can help you in doing all this in VMD.

##### SNFG Visualization:

On your keyboard, use the following shortcut keys:

‘i’ – apply the SNFG-Icons representation

‘g’ – apply the 3D-SNFG representation

‘b’ – apply the 3D-SNFG representation and label the reducing terminus

‘d’ – delete the drawn objects



### List of software

[Amber/AmberTools](https://ambermd.org/)

[Glycam-web](http://glycam.org/)

[VMD](http://www.ks.uiuc.edu/Research/vmd/)

[PyMOL](https://github.com/schrodinger/pymol-open-source)

[NAMD](http://www.ks.uiuc.edu/Research/namd/)



### Other useful tutorials:
[VMD: Images for Publication](https://www.youtube.com/watch?v=ip7lmmD7Z2k)

[Chimera MD Tutorial](https://www.cgl.ucsf.edu/chimera/docs/ContributedSoftware/md/md.html)

[Amber Tutorial](https://ambermd.org/tutorials/)



### Acknowledgement: 
3D implementation of the Symbol Nomenclature for Graphical Representation of Glycans. Glycobiology, 26(8), 786-787. DOI:10.1093/glycob/cww076)


