Evolutionary dynamics of mycorrhizal symbiosis in land plant diversification
============================================================================
![sequoia](doc/sekvoja-1.gif)

Trait data and analysis
-----------------------
This repository holds trait data data and scripts for part of the methods of the 
manuscript entitled _Evolutionary dynamics of mycorrhizal symbiosis in land plant 
diversification_ by Frida A.A. Feijen, Rutger A. Vos, Jorinde Nuytinck & 
Vincent S.F.T. Merckx. The contents of this repository are made available under
a [CC-BY](https://creativecommons.org/licenses/by/4.0/) license.

Directory structure:

- [data](data): contains verbatim input data and pruned/converted versions
- [script](script): contains conversion scripts
- [doc](doc): supporting documentation, manuscript files
- [results](results): final output files

## Methods

### Phylogenetic analysis

Plant systematists assign four different rootings of the land plants enough plausibility
that we consider them here. These four rootings are intended to orient the following 
major groups relative to one another: 
liverworts ([_Marchantiophyta_](http://eol.org/pages/6864901/overview)), 
mosses ([_Bryophyta_](http://eol.org/pages/3768/overview)), 
hornworts ([_Anthocerotophyta_](http://eol.org/pages/3678/overview)) and 
vascular plants ([_Tracheophyta_](http://eol.org/pages/4077/overview)).

- [**MBasal**](results/MBasal/MBasal.pdf) - liverworts split off first, followed by mosses, 
  and hornworts are sister to vascular plants. This yields the following topology: 
  `(((Anthocerotophyta,Tracheophyta),Bryophyta),Marchantiophyta);`  
- [**ABasal**](results/ABasal/ABasal.pdf) - hornworts branch off first, yielding the 
  following topology: 
  `(((Marchantiophyta,Bryophyta),Tracheophyta),Anthocerotophyta);`
- [**TBasal**](results/TBasal/TBasal.pdf) - vascular plants branch off first, yielding 
  the following topology: 
  `(((Marchantiophyta,Bryophyta),Anthocerotophyta),Tracheophyta);`
- [**ATxMB**](results/TBasal/TBasal.pdf) - liverworts and mosses (M,B) form a monophyletic 
  group, and so do hornworts and vascular plants (A,T), resulting in: 
  `((Marchantiophyta,Bryophyta),(Anthocerotophyta,Tracheophyta));`
  **In the manuscript, this is considered the preferred rooting, which we will explore 
  in more depth than the others.**

For each of these rootings, we performed a BEAST analysis to date the trees. The results
of these analysis are part of a separate (too-large-for-github) submission available at
[10.5281/zenodo.1037548](http://doi.org/10.5281/zenodo.1037548).

## Comparative analysis

Using the consensus trees, we performed phylogenetic comparative `multistate` analyses 
with the program [BayesTraits](http://www.evolution.rdg.ac.uk/BayesTraits.html), in which 
each state change is a transition that is modeled in a Q matrix, which is amenable to 
parameter restriction so that various hypotheses can be tested using Bayes Factors.

Because different higher taxa among the mycorrhiza can associate with land plants in 
[a variety of observed combinations](results/legend.pdf) there is potentially a very 
large number of states: if we treat every permutation of associations as a potential 
state we will end up with an explosion of parameters in the Q matrix such that the 
analysis becomes practically intractable. But, we can reduce the number of parameters 
in the following ways:

- We only take the empirically observed combinations of observations, not all 
  permutations (i.e. only [these](results/legend.pdf)).
- We disallow transitions where more than one association is gained or lost 
  instantaneously.
- We then do a Reversible Jump MCMC analysis to further reduce the Q matrix.

### Preparing the input data

To prepare our input data, we take the steps outlined below. Note that this assumes the 
following about the data:

1. The consensus trees are in Nexus format. Newick trees need to be converted to Nexus 
   first, e.g. using FigTree, Mesquite, etc.
2. The input data are a tabular file that must meet the following requirements: line 
   breaks in UNIX format, a single header line that at least enumerates all state symbols
   as a space-separated list between parentheses, all subsequent lines start with the 
   taxon name (spelled exactly the same as in the tree, including underscores for spaces),
   then one or more spaces (can be tabs), then the states, which can either be a single
   string or space (tab) separated.

### 1. Prepare input data files

First we make the raw input for BayesTraits/MultiState using the script 
`make_ms_input.pl`. Make sure that the data with associations is in the same format as 
HostFungusAssociations.txt or TableS1.txt. The key here is that each data line has the 
taxon name, some whitespace, and then a sequence of associations, with or without 
spaces in it. For each line, the first word is matched against the tips in the tree, 
any lines that don't match anything are assumed to be headers or footers and are 
ignored. When this happens, a warning is emitted by 
[make_ms_input.pl](script/make_ms_input.pl), as follows:
`putative taxon '$taxon' not in tree, ignoring (could also be table header)`
Note that you also need to capture STDOUT to make a states file, so the full command
would be:

    make_ms_input.pl -d <indata> -i <intree> -o <outtree> -t <outdata> > <states>

- `-d` location of input data file
- `-i` location of input tree file in Nexus format
- `-o` output Nexus tree file, reconciled with data
- `-t` output data in TSV format, reconciled with tree
- `> <states>` location to redirect states table to file

### 2. Generate BayesTraits command files

Then we create the BayesTraits/MultiState commands for restricting the transitions as
per the general idea described above. These commands will also ensure that the run is
done using reversible jump MCMC. Whether or not you use a hyperprior depends on whether
the script [make_restrictions.pl](script/make_restrictions.pl) was invoked with the 
`--hyper` flag. It is probably a good idea to do this. In addition, by default, the 
command file will configure a chain with 'infinite' iterations (i.e. -1) that needs to 
be interrupted manually. If you have a better idea about the number of iterations it is 
worth specifying that. A conservative estimate for the present project is 10*10^6 
generations, of which we will want to discard up to 50% burnin (in one case this 
appeared to be necessary). Lastly, it might make sense to indicate how many cores you 
have available for the analysis, although this only works for multi-core (e.g. OpenMP) 
versions. Hence, the full command would be:

    make_restrictions.pl -states <states.tsv> -tree <outtree> [-iterations <iterations>] 
    [-cores <cores>] [-hyper <min,max>] [-fossil <tip1,tip2=value>] [-restrict <qAB=qBA>]
    [-stones <min,max>]

- `-states` the redirected states table from the previous step
- `-tree` the Nexus tree file produced by the previous step
- `-iterations` optional, number of iterations, otherwise Inf
- `-cores` optional, number of CPU cores to use
- `-hyper` optional, range for the hyperprior, comma separated
- `-fossil` optional, fix a node (identified by tips) to a value
- `-restrict` optional, fix a rate
- `-stones` optional, configures the stepping stone sampler for marginal lnL
   
Once this is done we should have a tree file in Nexus format, a data file in tab-separated
spreadsheet format, and a text file with the restriction commands. You can now run the
analysis, as per the instructions below, or explore your data first in Mesquite to do a
visual check to see if it looks sane (probably a good idea).

### 3. (Optional) exploring your data in Mesquite

If you want to explore your data in Mesquite you can run the `make_nexus.pl` script. 
This script expects your data to be formatted with a header that enumerates all state 
symbols between parentheses, like the first line in HostFungusAssociations.txt and 
TableS1.txt. The full command would be:

    make_nexus.pl -d <indata> -t <outtree> > <outdata.nex>

You can then open this file in Mesquite and trace the character state changes (as 
reconstructed under maximum parsimony) on the tree topology.

### 4. Running a BayesTraits analysis

To run an analysis like this, we have to do the following steps:

1. install a Quad version of BayesTraits. This has higher precision to prevent underflows,
   which are somewhat possible because of the relatively large Q matrix.
2. open the program, i.e.:

    `BayesTraitsV2_OpenMP_Quad <tree.nex> <data.tsv> < restrictions.txt`

The data directory [data/2016-12-01](data/2016-12-01) contains various hypothesis tests 
applied to the `MBasal` rooting. The documentation there should also explain the rate 
constraint test applied to the either rootings, in directory 
[data/2017-03-06](data/2017-03-06). Together these analyses form the basis of the Bayes
factor analyses.

### 5. Visualizing BayesTraits results

The iteration of the workflow that produced the figures presented in the manuscript
was executed in [data/2017-10-06](data/2017-10-06). That directory's README contains 
more detailed information about the analysis steps.

# Results

The general outcomes of this project are:

* **A database of observed associations**, summarized [here](results/legend.pdf)
* **The four rootings**, given here as simplified topologies (PDFs): 
  - [ATxMB](results/ATxMB/ATxMB.pdf)
  - [ABasal](results/ABasal/ABasal.pdf)  
  - [MBasal](results/MBasal/MBasal.pdf)
  - [TBasal](results/TBasal/TBasal.pdf)
* **Reconstruction of the root states**, visualized as pie charts for the four roots:
  - [ATxMB](results/ATxMB_pie_simple.pdf)  
  - [ABasal](results/ABasal_pie_simple.pdf)
  - [MBasal](results/MBasal_pie_simple.pdf)
  - [TBasal](results/TBasal_pie_simple.pdf)
* **Hypothesis testing results**, collected in a [table](results/RateConstraints.xlsx) 
  of the constraints tested on the four rootings, in triplicate, and compared with 
  unconstrained runs, significant differences calculated as Bayes factors.
* **Reconstruction of the interior nodes**, for the preferred rooting (`ATxMB`) a 
  reconstruction of the ancestral states for all the nodes: 
  - [manuscript phylogram and higher taxa](results/ATxMB/ATxMB_radial_ms.pdf)
  - [supplementary cladogram with pie chars](results/ATxMB/ATxMB_radial_supp.pdf)
* **Estimates of state transition rates**, for the preferred rooting visualized as:
  - [HTML/D3 Circos graph](results/Circos/d3.html)
  - [PDF Circos graph](results/Circos/d3.pdf)
* **Sliding window analysis of states**, visualized as:
  - [states through time plot](data/StatesThroughTime/StatesThroughTime-bin50.pdf) that
    shows which likelihood pie slices dominated sliding windows from the root of the tree
    to the present.
