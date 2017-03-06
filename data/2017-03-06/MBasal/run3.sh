#!/bin/bash
mkdir run3
cp Tree.nex.bt.nex run3
cp ../HostFungusAssociations.txt.tsv run3
cd run3
BT3.0-OSX-openMP Tree.nex.bt.nex ../HostFungusAssociations.txt.tsv < ../unconstrained.txt
mv ../HostFungusAssociations.txt.tsv.log.txt ../HostFungusAssociations.txt.unconstrained.log
mv ../HostFungusAssociations.txt.tsv.log.txt.Stones.txt ../HostFungusAssociations.txt.unconstrained.Stones.txt
