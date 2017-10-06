#!/bin/bash
TREE=Tree.nex.bt.nex
ASSOC=A,B,G,M
LOG=merged.log
STATES=states.tsv
DATA=HostFungusAssociations.txt.tsv
PHYLA=phyla.tsv
WIDTH=3000
HEIGHT=4000
BURNIN=500000

# HERE WE MAKE THE FIGURE FOR IN THE MANUSCRIPT

# to make a phylogram, set this to 'phylo'
MODE=phylo

# to change node radius, e.g. to hide pies, set to 1
RADIUS=0

# to hide pies, set to 'no'
PIES=no

# to hide tips, set to 'no'
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
	-taxa $PHYLA \
	-config radius=$RADIUS \
	-config pies=$PIES \
	-config tips=$TIPS \
	-config width=6 \
	-burnin $BURNIN > $TREE.ms.svg

# HERE WE MAKE THE SUPPLEMENTARY FIGURE

# to make a phylogram, set this to 'phylo'
MODE=clado

# to change node radius, e.g. to hide pies, set to 1
RADIUS=12

# to hide pies, set to 'no'
PIES=yes

# to hide tips, set to 'no'
TIPS=yes

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
	-config width=2 \
	-burnin $BURNIN > $TREE.supp.svg