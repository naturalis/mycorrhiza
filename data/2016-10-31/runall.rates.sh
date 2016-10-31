#!/bin/bash

# This is where $RATES, $STATES, $LEFT and $RIGHT will come from
source env.sh

# Input tree in nexus format. Branch lengths rescaled to an average of 0.1, hence
# the rate hyperprior now has a range of 0,100 instead of 0,0.5, as the scaling 
# factor (where branches were previously in myr) is about 0.00351459194994031 for the
# branches, and 1/0.00351459194994031 = 284.52805168946668 for the rates
TREE=Mbasal_mod1.bt.rescaled.nex

# Input data as tab-separated file
DATA=HostFungusAssociations.tsv

# New BayesTraits executable courtesy of Andrew
BT=BT3.0-OSX-openMP

# iterate over rates from env.sh
for RATE in $RATES; do

	# create the command file, restricting the $RATE to 0
	perl ../../script/make_restrictions.pl \
		-states states.tsv \
		-tree $TREE \
		-hyper 0,100 \
		-iterations 1000000 \
		-cores 4 \
		-restrict $RATE=0 \
		-stones 100,200000 \
		-newapi > restrictions.$RATE.0.txt
		
	# run the analysis
	$BT $TREE $DATA < restrictions.$RATE.0.txt
	
	# rename log and stones file so it's not overwritten
	mv $DATA.log.txt $DATA.log.$RATE.0.txt
	mv $DATA.log.txt.Stones.txt $DATA.log.txt.Stones.$RATE.0.txt
done

# iterate over states from env.sh
for STATE in $STATES; do

	# create the command file, fixing the fossil root to $STATE
	perl ../../script/make_restrictions.pl \
		-states states.tsv \
		-tree $TREE \
		-hyper 0,100 \
		-iterations 1000000 \
		-cores 4 \
		-fossil $LEFT,$RIGHT=$STATE \
		-stones 100,200000 \
		-newapi > restrictions.root.$STATE.txt
		
	# run the analysis
	$BT $TREE $DATA < restrictions.root.$STATE.txt
	
	# rename log and stones file so it's not overwritten
	mv $DATA.log.txt $DATA.log.root.$STATE.txt
	mv $DATA.log.txt.Stones.txt $DATA.log.txt.Stones.root.$STATE.txt
done
