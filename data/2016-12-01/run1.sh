#!/bin/bash
mkdir run1
cp Mbasal_mod1.bt.rescaled.nex run1
cp HostFungusAssociations.txt.tsv run1
cd run1
BT3.0-OSX-openMP Mbasal_mod1.bt.rescaled.nex HostFungusAssociations.txt.tsv < ../unconstrained.txt
mv HostFungusAssociations.txt.tsv.log.txt HostFungusAssociations.txt.unconstrained.log
BT3.0-OSX-openMP Mbasal_mod1.bt.rescaled.nex HostFungusAssociations.txt.tsv < ../constrained.qHG.0.txt
mv HostFungusAssociations.txt.tsv.log.txt HostFungusAssociations.txt.qHG.0.log
BT3.0-OSX-openMP Mbasal_mod1.bt.rescaled.nex HostFungusAssociations.txt.tsv < ../constrained.qHD.0.txt
mv HostFungusAssociations.txt.tsv.log.txt HostFungusAssociations.txt.qHD.0.log
BT3.0-OSX-openMP Mbasal_mod1.bt.rescaled.nex HostFungusAssociations.txt.tsv < ../constrained.qHB.0.txt
mv HostFungusAssociations.txt.tsv.log.txt HostFungusAssociations.txt.qHB.0.log
BT3.0-OSX-openMP Mbasal_mod1.bt.rescaled.nex HostFungusAssociations.txt.tsv < ../constrained.qHI.0.txt
mv HostFungusAssociations.txt.tsv.log.txt HostFungusAssociations.txt.qHI.0.log
