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

# define list of runs
RUNS="run1 run2 run3"

# iterate over runs
for RUN in $RUNS; do

	# make dir if needed
	if [ ! -d $RUN ]; then
		mkdir $RUN
	fi

	# iterate over rates from env.sh
	for RATE in $RATES; do

		# don't re-run
		if [ ! -e $DATA.log.txt.Stones.$RATE.0.txt ]; then
		
			# run the analysis
			$BT $TREE $DATA < restrictions.$RATE.0.txt
	
			# rename log and stones file so it's not overwritten
			mv $DATA.log.txt $RUN/$DATA.log.$RATE.0.txt
			mv $DATA.log.txt.Stones.txt $RUN/$DATA.log.txt.Stones.$RATE.0.txt
		fi
	done

	# iterate over states from env.sh
	for STATE in $STATES; do

		# don't re-run
		if [ ! -e $DATA.log.txt.Stones.root.$STATE.txt ]; then
		
			# run the analysis
			$BT $TREE $DATA < restrictions.root.$STATE.txt
	
			# rename log and stones file so it's not overwritten
			mv $DATA.log.txt $RUN/$DATA.log.root.$STATE.txt
			mv $DATA.log.txt.Stones.txt $RUN/$DATA.log.txt.Stones.root.$STATE.txt
		fi
	done
	
	# do the unconstrained run
	$BT $TREE $DATA < unconstrained.txt
	mv $DATA.log.txt $RUN/$DATA.log.unconstrained.txt
	mv $DATA.log.txt.Stones.txt $RUN/$DATA.log.txt.Stones.unconstrained.txt
	
done