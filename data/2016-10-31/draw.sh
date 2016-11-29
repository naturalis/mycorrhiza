#!/bin/bash
TREE=Mbasal_mod1.bt.rescaled.nex
ASSOC=A,B,G,M
LOG=run2/HostFungusAssociations.tsv.log.txt
STATES=states.tsv
DATA=HostFungusAssociations.tsv
WIDTH=3000
HEIGHT=4000
BURNIN=500000

perl ../../script/visualize.pl \
	-verbose \
	-assoc $ASSOC \
	-tree $TREE \
	-states $STATES \
	-log $LOG \
	-data $DATA \
	-width $WIDTH \
	-height $HEIGHT \
	-burnin $BURNIN > $TREE.svg
