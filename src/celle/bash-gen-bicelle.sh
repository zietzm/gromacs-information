#!/bin/bash
set -e

### Requires the following files:
### bash-gen-bicelle.sh
### em.mdp
### md-martini.mdp
### md-posre.mdp
### py-comp-change.py
### py-general-top.py
### py-remove-water.py
### py-reorder.py
### README.md
### str-dppc-bilayer.gro
### str-water.gro
### top-dppc-posre.itp
### top-dppc-posre-all.itp
### top-dppc-single.itp
### top-dtpc-posre.itp
### top-dtpc-posre-all.itp
### top-dtpc-single.itp
### top-martini-v2.1.itp

source /usr/local/gromacs/bin/GMXRC

python py-comp-change.py str-dppc-bilayer.gro gmx-mixed-bilayer
python py-general-top.py gmx-mixed-bilayer.gro gmx-mixed-top.top single

grompp -f em.mdp -c gmx-mixed-bilayer.gro -p gmx-mixed-top.top -maxwarn 10 -o em-mix-bil.tpr
mdrun -deffnm em-mix-bil -v -nt 1

genconf -f em-mix-bil.gro -o gmx-replicated.gro -nbox 4 4 1
editconf -f gmx-replicated.gro -o gmx-large.gro -box 32 32 12

python py-remove-water.py gmx-large.gro gmx-nowater.gro
genbox -cp gmx-nowater.gro -cs str-water.gro -vdwd 0.21 -o gmx-full-water.gro

python py-reorder.py gmx-full-water.gro gmx-ordered
python py-general-top.py gmx-full-water.gro gmx-large-top.top single
python py-general-top.py gmx-full-water.gro gmx-posre-top.top posre
python py-general-top.py gmx-full-water.gro gmx-posre-all-top.top posre-all

grompp -f em.mdp -c gmx-ordered.gro -p gmx-posre-all-top.top -maxwarn 10 -o em-watermin.tpr
mdrun -deffnm em-watermin -v 
grompp -f em.mdp -c em-watermin.gro -p gmx-posre-top.top -maxwarn 10 -o em-prm.tpr
mdrun -deffnm em-prm -v
grompp -f md-posre.mdp -c em-prm.gro -p gmx-posre-top.top -maxwarn 10 -o em-posre.tpr
mdrun -deffnm em-posre -v
grompp -f md-martini.mdp -c em-posre.gro -p gmx-large-top.top -maxwarn 10 -o md-pr.tpr
mdrun -deffnm md-pr -v
