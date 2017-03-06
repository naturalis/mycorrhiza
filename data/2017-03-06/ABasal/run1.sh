#!/bin/bash
mkdir run1
cp Tree.nex.bt.nex run1
cp ../HostFungusAssociations.txt.tsv run1
cd run1
BT3.0-OSX-openMP Tree.nex.bt.nex ../HostFungusAssociations.txt.tsv < ../unconstrained.txt
mv ../HostFungusAssociations.txt.tsv.log.txt ../HostFungusAssociations.txt.unconstrained.log
mv ../HostFungusAssociations.txt.tsv.log.txt.Stones.txt ../HostFungusAssociations.txt.unconstrained.Stones.txt
