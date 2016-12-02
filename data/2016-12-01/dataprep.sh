#!/bin/bash

SCRIPT=../../script/
TREE=Mbasal_mod1.bt.rescaled.nex
DATA=HostFungusAssociations.txt
STATES=states.tsv

# New BayesTraits executable courtesy of Andrew
BT=BT3.0-OSX-openMP

# this script does the following:
# 1. maps presence/absence bitmasks to single character states, e.g. 0000 => A
# 2. exports a version of the data matrix that uses these single characters, as TSV
# 3. exports a file that contains the mappings, "states.tsv"
# 4. prunes taxa without data from the tree 
# In the 2016-12-01 analyses this not needed: the taxa already match. Hence, the tree
# that is exported can be ignored.
perl $SCRIPT/make_ms_input.pl \
	-data $DATA \
	-in $TREE \
	-out $TREE.bt.nex \
	-table $DATA.tsv \
	-verbose \
	> $STATES

# this script generates command files for BayesTraits. We restrict transitions from 0000
# (which is coded as H) to any of the following:
# - G => 0001, associated with M
# - D => 0010, associated with G
# - B => 0100, associated with B
# - I => 1000, associated with A
CODES="G D B I"
for CODE in $CODES; do
	perl $SCRIPT/make_restrictions.pl \
		-states $STATES \
		-tree $TREE.bt.nex \
		-hyper 0,100 \
		-iterations 1000000 \
		-cores 4 \
		-stones 100,200000 \
		-restrict qH${CODE}=0 \
		-newapi > constrained.qH${CODE}.0.txt
done

# we also need an unconstrained command file
perl $SCRIPT/make_restrictions.pl \
	-states $STATES \
	-tree $TREE.bt.nex \
	-hyper 0,100 \
	-iterations 1000000 \
	-cores 4 \
	-stones 100,200000 \
	-newapi > unconstrained.txt

# we will do three runs for each command file
RUNS="run1 run2 run3"
for RUN in $RUNS; do
	echo "#!/bin/bash" > $RUN.sh
	echo "mkdir $RUN"  >> $RUN.sh
	echo "cp $TREE $RUN" >> $RUN.sh
	echo "cp $DATA.tsv $RUN" >> $RUN.sh
	echo "cd $RUN" >> $RUN.sh
	echo "$BT $TREE $DATA.tsv < ../unconstrained.txt" >> $RUN.sh
	echo "mv $DATA.tsv.log.txt $DATA.unconstrained.log" >> $RUN.sh
	echo "mv $DATA.tsv.log.txt.Stones.txt $DATA.unconstrained.Stones.txt" >> $RUN.sh
	for CODE in $CODES; do
		echo "$BT $TREE $DATA.tsv < ../constrained.qH${CODE}.0.txt" >> $RUN.sh
		echo "mv $DATA.tsv.log.txt $DATA.qH${CODE}.0.log" >> $RUN.sh
		echo "mv $DATA.tsv.log.txt.Stones.txt $DATA.qH${CODE}.0.Stones.txt" >> $RUN.sh
	done
done
