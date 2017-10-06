This directory combines input data and analysis results from various previous iterations
in order to arrive at updated visualizations based on the ATxMB rooting. In particular,
the following files are here:

- input for the [BayesTraits analysis of ATxMB from 2017-03-06](../2017-03-06/ATxMB), 
  particularly, the [states encoding](../2017-03-06/ATxMB/states.tsv), the pruned, 
  name-cleaned [input tree](../2017-03-06/ATxMB/Tree.nex.bt.nex), and the output logs
  from [run1](../2017-03-06/ATxMB/run1/HostFungusAssociations.txt.unconstrained.log.gz), 
  [run2](../2017-03-06/ATxMB/run2/HostFungusAssociations.txt.unconstrained.log.gz), and 
  [run3](../2017-03-06/ATxMB/run3/HostFungusAssociations.txt.unconstrained.log.gz), 
  which have been averaged here using [the log merging script](../../script/logmerge.pl)
  to produce the [merged log](merged.log).
- a new driver [script](draw.sh) for tree visualization, and the resulting
  [cladogram](Tree.nex.bt.nex.supp.svg) and [phylogram](Tree.nex.bt.nex.ms.svg)
- a new [Q matrix](qmatrix.tsv), generated with the [qmatrix.pl](../../script/qmatrix.pl)
  script using: `perl ../../script/qmatrix.pl -l merged.log -s states.tsv > qmatrix.tsv`