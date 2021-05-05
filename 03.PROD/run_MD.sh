#!/bin/bash
source /usr/local/amber20/amber.sh
export CUDA_VISIBLE_DEVICES=0

#run MD
pmemd.cuda -O -i prod.in -p structure.parm7 -c equil10.rst7 -o prod01.out -r prod01.rst7 -x prod01.traj

