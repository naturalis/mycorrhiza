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
  [cladogram](Tree.nex.bt.nex.supp.svg) (with ancestral state pies and all species names,
  intended as supplementary figure, also see [pdf](Tree.nex.bt.nex.supp.pdf) version) and 
  [phylogram](Tree.nex.bt.nex.ms.svg) (branch lengths, higher taxon labels, no pies,
  summarized version intended for the main manuscript, also see [pdf](Tree.nex.bt.nex.ms.pdf) 
  version).
- a new [Q matrix](qmatrix.tsv), generated with the [qmatrix.pl](../../script/qmatrix.pl)
  script using: `perl ../../script/qmatrix.pl -l merged.log -s states.tsv > qmatrix.tsv`,
  the Q matrix imported in [a D3/HTML document](d3.html) and a [PDF version](d3.pdf) of
  the D3 visualization.
- `perl ../../script/states_through_time.pl -t Tree.nex.bt.nex -l merged.log -v > stt.tsv`
  to produce a [states-through-time](stt.tsv) file, which was further simplified using:
  `perl ../../script/simplify-stt.pl -s stt.tsv > stt-simplified.tsv`, yielding
  [stt-simplified.tsv](stt-simplified.tsv). This was then incorporated into a 
  [spreadsheet](StatesThroughTime-bin50.xlsx) to produce a 
  [visualization](StatesThroughTime-bin50.pdf) of the ancestral state reconstructions 
  averaged over all the nodes inside bins of 50myr.
