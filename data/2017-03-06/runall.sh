#!/bin/bash

ROOTINGS="ABasal ATxMB TBasal"
RUNS="run1 run2 run3"
CONSTRAINTS="qHB qHD qHG qHI"
WD=`pwd`

BT=BT3.0-OSX-openMP
TREE=Tree.nex.bt.nex
DATA=../HostFungusAssociations.txt.tsv

# iterate over the three other rootings besides MBasal
for ROOTING in $ROOTINGS; do

	# iterate over the constraints, i.e. NA -> {A,B,G,M} = 0
	for CONSTRAINT in $CONSTRAINTS; do
	
		# iterate over the triplicates
		for RUN in $RUNS; do
			cd $WD/$ROOTING/$RUN
			COMMANDS=../constrained.${CONSTRAINT}.0.txt
			$BT $TREE $DATA < $COMMANDS
			
			# move results to run folder and rename to prevent clobbering
			mv ../HostFungusAssociations.txt.tsv.log.txt HostFungusAssociations.txt.${CONSTRAINT}.log
			mv ../HostFungusAssociations.txt.tsv.log.txt.Stones.txt HostFungusAssociations.txt.${CONSTRAINT}.Stones.txt
			
			# add the marginal likelihood estimation result to github
			git add HostFungusAssociations.txt.${CONSTRAINT}.Stones.txt
			git commit -m "adding $ROOTING $CONSTRAINT=0 $RUN result" HostFungusAssociations.txt.${CONSTRAINT}.Stones.txt
			git push
		done
	done
done