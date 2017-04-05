# Comparative analysis of associations between land plants and mycorrhiza

This repository holds data and scripts to analyze associations between land plants and 
mycorrhiza. This is a collaboration between Vincent Merckx, Frida Feijen, Jorinde Nuytinck
and Rutger Vos. Directory structure:

- data: contains verbatim input data and pruned/converted versions thereof
- script: contains conversion scripts
- doc: supporting documentation
- results: final output files

# Goals

The general aims of this project, and the usage that the files in this repository are put
to, are:

- For the four possible rootings (identified as `ABasal`, `ATxMB`, `MBasal`, and `TBasal`)
  to reconstruct the root states. These will be visualized as likelihood pies for the four
  root nodes.
- For the preferred rooting (`MBasal`) to reconstruct the likelihood pies for all the 
  nodes and visualize these on a [radial tree](data/2016-11-17/Mbasal_mod1.bt.rescaled.nex.svg).
- For the state transitions on the preferred rooting to be visualized somehow, for example
  as [communicating compartments](results/IMG_1732.jpg) or as a 
  [circos-style graph](doc/circos.jpg) (for the latter, we'd have to use D3, not circos,
  because in- and outflows need different sizes).
- For there to be an enumeration of the most likely scenarios by which the initial 
  association between mycorrhiza and land plants came about, with their relative support
  by the data quantified.
  
Since phylogenetic inference under different rooting scenarios has already been performed
by Frida at the outset of the analyses recorded here, the most computationally intensive 
steps that need to be taken involve ancestral state reconstruction. In a previous 
iteration, Frida had done this using a dispersal model where state changes were modeled as 
migrations. Here we will instead do the analysis in a more standard way, using 
[BayesTraits](http://www.evolution.rdg.ac.uk/BayesTraits.html), so that each state change 
is a transition that is modeled in a Q matrix, which is amenable to parameter restriction
so that various hypotheses can be tested using Bayes Factors.

## Preamble: restricting the number of transitions, the general idea

Because different higher taxa among the mycorrhiza can associate with land plants in 
different combinations there is potentially a very large number of states: if we treat 
every permutation of associations as a potential state within the context of a 
phylogenetic comparative analysis we will end up with an explosion of parameters in the Q 
matrix such that the analysis becomes practically intractable. But, we can reduce the 
number of parameters in the following ways:

- We only take the empirically observed combinations of observations, not all 
  permutations.
- We disallow transitions where more than one association is gained or lost 
  instantaneously.
- We then do a Reversible Jump MCMC analysis to further reduce the Q matrix.

## Preamble: the different rootings to consider

Plant systematists assign four different rootings of the land plants enough plausibility
that we consider them here. These four rootings are intended to orient the following 
major groups relative to one another: 
liverworts ([_Marchantiophyta_](http://eol.org/pages/6864901/overview)), 
mosses ([_Bryophyta_](http://eol.org/pages/3768/overview)), 
hornworts ([_Anthocerotophyta_](http://eol.org/pages/3678/overview)) and 
vascular plants ([_Tracheophyta_](http://eol.org/pages/4077/overview)).

- `MBasal` - liverworts split off first, followed by mosses, and hornworts are sister to 
  vascular plants. This yields the following topology: 
  `(((Anthocerotophyta,Tracheophyta),Bryophyta),Marchantiophyta);`
  **This is the preferred rooting, which we will explore in more depth than the others.**
- `ABasal` - hornworts branch off first, yielding the following topology: 
  `(((Marchantiophyta,Bryophyta),Tracheophyta),Anthocerotophyta);`
- `TBasal` - vascular plants branch off first, yielding the following topology: 
  `(((Marchantiophyta,Bryophyta),Anthocerotophyta),Tracheophyta);`
- `ATxMB` - liverworts and mosses (M,B) form a monophyletic group, and so do
  hornworts and vascular plants (A,T), resulting in: 
  `((Marchantiophyta,Bryophyta),(Anthocerotophyta,Tracheophyta));`

## Preparing the input data

To prepare our input data, for an analysis as described above using the program 
BayesTraits (specifically, the MultiState mode of this program) we have to do the steps 
outlined below. Note that this assumes the following about the data:

1. The input trees are in Nexus format. Newick trees need to be converted to Nexus first,
   e.g. using FigTree, Mesquite, etc.
2. The input data are a tabular file that must meet the following requirements: line 
   breaks in UNIX format, a single header line that at least enumerates all state symbols
   as a space-separated list between parentheses, all subsequent lines start with the 
   taxon name (spelled exactly the same as in the tree, including underscores for spaces),
   then one or more spaces (can be tabs), then the states, which can either be a single
   string or space (tab) separated.

### 1. Make input data

First we make the raw input for BayesTraits/MultiState using the script `make_ms_input.pl`.
Make sure that the data with associations is in the same format as 
HostFungusAssociations.txt or TableS1.txt. The key here is that each data line has the 
taxon name, some whitespace, and then a sequence of associations, with or without 
spaces in it. For each line, the first word is matched against the tips in the tree, 
any lines that don't match anything are assumed to be headers or footers and are 
ignored. When this happens, a warning is emitted by `make_ms_input.pl`, as follows:
`putative taxon '$taxon' not in tree, ignoring (could also be table header)`
Note that you also need to capture STDOUT to make a states file, so the full command
would be:

    make_ms_input.pl -d <indata> -i <intree> -o <outtree> -t <outdata> > <states>

### 2. Make restriction commands

Then we create the BayesTraits/MultiState commands for restricting the transitions as
per the general idea described above. These commands will also ensure that the run is
done using reversible jump MCMC. Whether or not you use a hyperprior depends on whether
the script `make_restrictions.pl` was invoked with the `--hyper` flag. It is probably a 
good idea to do this. In addition, by default, the command file will configure a chain 
with 'infinite' iterations (i.e. -1) that needs to be interrupted manually. If you have 
a better idea about the number of iterations it is worth specifying that. A conservative
estimate for the present project is 10*10^6 generations, of which we will want to discard
up to 50% burnin (in one case this appeared to be necessary). Lastly, it might make sense
to indicate how many cores you have available for the analysis, although this only works 
for multi-core (e.g. OpenMP) versions. Hence, the full command would be:

    make_restrictions.pl -states <states.tsv> -tree <outtree> [-iterations <iterations>] 
    [-cores <cores>] [-hyper <min,max>] [-fossil <tip1,tip2=value>] [-restrict <qAB=qBA>]
    [-stones <min,max>]
   
Once this is done we should have a tree file in Nexus format, a data file in tab-separated
spreadsheet format, and a text file with the restriction commands. You can now run the
analysis, as per the instructions below, or explore your data first in Mesquite to do a
visual check to see if it looks sane (probably a good idea).

## Exploring your data

If you want to explore your data in Mesquite you can run the `make_nexus.pl` script. 
This script expects your data to be formatted with a header that enumerates all state 
symbols between parentheses, like the first line in HostFungusAssociations.txt and 
TableS1.txt. The full command would be:

    make_nexus.pl -d <indata> -t <outtree> > <outdata.nex>

You can then open this file in Mesquite and trace the character state changes (as 
reconstructed under maximum parsimony) on the tree topology.

## Running an analysis

To run an analysis like this, we have to do the following steps:

1. install a Quad version of BayesTraits. This has higher precision to prevent underflows,
   which are somewhat possible because of the relatively large Q matrix.
2. open the program, i.e. `BayesTraitsV2_OpenMP_Quad <tree.nex> <data.tsv> < restrictions.txt`

## Post-analysis processing

Once the analysis is completed we will have a large file with samples of rates from the Q
matrix and samples of states at the various internal nodes. Presumably these will have to 
be visualized using likelihood pies and colored branches. Perhaps we will have some use 
out of the earlier work done for 
[naturalis/asterid-phylo-comp](http://github.com/naturalis/asterid-phylo-comp).
