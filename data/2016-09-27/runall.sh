#!/bin/bash
DIRS="Abasal2 ATxMB2 Mbasal2 Tbasal2"
for DIR in $DIRS; do
	cd $DIR
	if [ ! -e "TableS1.tsv.log.txt" ]; then
		BayesTraitsV2_OpenMP_Quad $DIR.dnd.nex.btin.nex TableS1.tsv < restrictions.txt
	fi
	cd ..
done
