#!/bin/bash
TREE=Mbasal_mod1.bt.rescaled.nex
ASSOC=A,B,G,M
LOG=run2/HostFungusAssociations.txt.unconstrained.log
STATES=states.tsv
DATA=HostFungusAssociations.txt.tsv
WIDTH=3000
HEIGHT=4000
BURNIN=500000

# to make a phylogram, set this to 'phylo'
#MODE=clado
MODE=phylo

# to change node radius, e.g. to hide pies, set to 1
#RADIUS=12
RADIUS=0

# to hide pies, set to 'no'
#PIES=yes
PIES=no

# to hide tips, set to 'no'
#TIPS=yes
TIPS=no

perl ../../script/visualize.pl \
	-verbose \
	-assoc $ASSOC \
	-tree $TREE \
	-states $STATES \
	-log $LOG \
	-data $DATA \
	-width $WIDTH \
	-height $HEIGHT \
	-mode $MODE \
	-config radius=$RADIUS \
	-config pies=$PIES \
	-config tips=$TIPS \
	-burnin $BURNIN > $TREE.svg