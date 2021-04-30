# Molecular Dynamics of Glycoprotein

## Aimed at:
Anyone interested in learning  MD simulations for their research, in particular for studying glycoproteins or protein/glycan cimplexes.

### Requirements:
Basic knowledge the Linux command line molecular dynamics theory.

### Abstract:
The training workshop will introduce non-specialists to the use of MD simulations for modelling lycoproteins or protein/glycan cimplexes. Concepts and techniques of MD simulations will be explained through hands-on exercises. During the tutorial, each participant will perform MD simulation of sheep signalling glycoprotein (SPS-40) complex with 2-methyl-2-4-pentanediol. 

### Training Material
The tutorial workshop consists of a series of scripts to run the simulations and analysis of the outputs, accompanied by an informal lecture. The scripts can be run using the CCBRC training server, fucose.

Once you will login to fucose workstation open a Terminal (Click "New" top-right of the item list, and choose "Terminal" from the list). You will find the scripts and all other required workshop files there. Once you are finished, please copy all the data and "logout" from the server by pressing Ctrl +D.

All material was prepared by Sushil Kumar Mishra.

### Contents
In this tutorial workshop, you will learn how to apply combined quantum mechanics/molecular mechanics (QM/MM) methods to model a chemical reaction in an enzyme. You will calculate a free energy profile and a potential energy profile for the reaction, and analyse an important interaction in the active site.

You will be using the simulation software from the AmberTools package. The sander programme is capable of the QM/MM simulations required. For efficiency, the semi-empirical QM method PM6 will be used throughout (implemented directly in sander). You can further use VMD to visualise the simulations on your local machine (after downloading the final files).

You will be simulating the enzyme-catalysed reaction of chorismate to prephenate. This is an intramolecular reaction. The reaction proceeds via a cyclic transition state. A (geometric) reaction coordinate can be defined as the difference between the length of the C-O bond that is breaking, and the length of the C-C bond that is forming. Plotting the energy of the molecule as a function of this reaction coordinate returns a reaction energy profile.

Acknowledgement: 
Parts of the text has been adompted from CCPBioSim, qm/mm workshop. Source 
