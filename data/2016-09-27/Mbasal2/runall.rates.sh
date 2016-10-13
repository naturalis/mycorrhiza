#!/bin/bash
TREE=Mbasal2.dnd.nex.btin.nex
DATA=TableS1.tsv
RATES="qDC qBA qEI qFK qGH"
for RATE in $RATES; do
	BayesTraitsV2_OpenMP_Quad $TREE $DATA < restrictions.$RATE.0.txt
	mv TableS1.tsv.log.txt TableS1.tsv.log.$RATE.0.txt
	mv TableS1.tsv.log.txt.Stones.txt TableS1.tsv.log.txt.Stones.$RATE.0.txt
done

STATES="A B C D"
for STATE in $STATES; do
	BayesTraitsV2_OpenMP_Quad $TREE $DATA < restrictions.root.$STATE.txt
	mv TableS1.tsv.log.txt TableS1.tsv.log.root.$STATE.txt
	mv TableS1.tsv.log.txt.Stones.txt TableS1.tsv.log.txt.Stones.root.$STATE.txt
done
