#!/bin/bash
mkdir run2
cp Tree.nex.bt.nex run2
cp ../HostFungusAssociations.txt.tsv run2
cd run2
BT3.0-OSX-openMP Tree.nex.bt.nex ../HostFungusAssociations.txt.tsv < ../unconstrained.txt
mv ../HostFungusAssociations.txt.tsv.log.txt ../HostFungusAssociations.txt.unconstrained.log
mv ../HostFungusAssociations.txt.tsv.log.txt.Stones.txt ../HostFungusAssociations.txt.unconstrained.Stones.txt
