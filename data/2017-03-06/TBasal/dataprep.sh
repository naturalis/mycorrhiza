#!/bin/bash

SCRIPT=../../../script/
TREE=Tree.nex
DATA=../HostFungusAssociations.txt
STATES=states.tsv

# New BayesTraits executable courtesy of Andrew
BT=BT3.0-OSX-openMP

# this script does the following:
# 1. maps presence/absence bitmasks to single character states, e.g. 0000 => A
# 2. exports a version of the data matrix that uses these single characters, as TSV
# 3. exports a file that contains the mappings, "states.tsv"
# 4. prunes taxa without data from the tree 
# In the 2016-12-01 analyses (and onwards) this is technically not needed: the taxa 
# already match. Hence, the tree that is exported might be ignored (but verify this).
perl $SCRIPT/make_ms_input.pl \
	-data $DATA \
	-in $TREE \
	-out $TREE.bt.nex \
	-table $DATA.tsv \
	-verbose \
	> $STATES

# this script generates a BayesTraits command file
perl $SCRIPT/make_restrictions.pl \
	-states $STATES \
	-tree $TREE.bt.nex \
	-hyper 0,100 \
	-iterations 1000000 \
	-cores 4 \
	-stones 100,200000 \
	-newapi > unconstrained.txt

# we will do three runs for the command file
RUNS="run1 run2 run3"
for RUN in $RUNS; do
	echo "#!/bin/bash" > $RUN.sh
	echo "mkdir $RUN"  >> $RUN.sh
	echo "cp $TREE.bt.nex $RUN" >> $RUN.sh
	echo "cp $DATA.tsv $RUN" >> $RUN.sh
	echo "cd $RUN" >> $RUN.sh
	echo "$BT $TREE.bt.nex $DATA.tsv < ../unconstrained.txt" >> $RUN.sh
	echo "mv $DATA.tsv.log.txt $DATA.unconstrained.log" >> $RUN.sh
	echo "mv $DATA.tsv.log.txt.Stones.txt $DATA.unconstrained.Stones.txt" >> $RUN.sh
done
