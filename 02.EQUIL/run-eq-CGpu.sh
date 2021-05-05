#!/bin/bash

source /usr/local/amber20/amber.sh

export pmemd_bin="mpirun -np 12 pmemd.MPI"
export amber_bin=pmemd.cuda


#----exicution part----#
ST_OF_WAT_RESIDUE=`grep "WAT" ../01.PREP/structure.pdb | head -1 | awk '{print $5}'`
NUM_OF_SOLUTE_RESIDUES=$((ST_OF_WAT_RESIDUE - 1))
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


echo "Exicution Finished "
