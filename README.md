# Comparative analysis of associations between land plants and mycorrhiza

This repository holds data and scripts to analyze associations between land plants and 
mycorrhiza. This is a collaboration between Vincent Merckx, Frida Feijen and Rutger Vos.
Directory structure:

- data: contains verbatim input data and pruned/converted versions thereof
- script: contains conversion scripts

## Preamble: restricting the number of transitions, the general idea

Because different higher taxa among the mycorrhiza can associate with land plants in 
different combinations there is potentially a very large number of states, that is,
permutations of associations. If we treat every permutation of associations as a potential
state within the context of a phylogenetic comparative analysis we will end up with an
explosion of parameters in the Q matrix such that the analysis becomes practically 
intractable. But, we can reduce the number of parameters in the following ways:

1. We only take the empirically observed combinations of observations, not all 
   permutations.
2. We disallow transitions where more than one association is gained or lost 
   instantaneously.
3. We then do a Reversible Jump MCMC analysis to further reduce the Q matrix.

## Preparing the input data

To prepare our input data, for an analysis as described above using the program 
BayesTraits (specifically, the MultiState mode of this program) we have to do the steps 
outlined below. Note that this assumes the following about the data:

1. The input trees are in Nexus format. Newick trees need to be converted to Nexus first,
   e.g. using FigTree, Mesquite, etc.
2. The input data are a tabular file that must meet the following requirements: line 
   breaks in UNIX format, a single header line that at least enumerates all state symbols
   as a space-separated list between parenthesis, all subsequent lines start with the 
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
the script `make_restrictions.pl` was invoked with the `--hyper` flag. It is probably
a good idea to do this, so the full command would be:

    make_restrictions.pl -s <states> -t <outtree> --hyper
   
Once this is done we should have a tree file in Nexus format, a data file in tab-separated
spreadsheet format, and a text file with the restriction commands. You can now run the
analysis, as per the instructions below.

## Exploring your data

If you want to explore your data in Mesquite you can run the `make_nexus.pl` script. 
This script expects your data to be formatted with a header that enumerates all state 
symbols between parentheses, like the first line in HostFungusAssociations.txt and 
TableS1.txt. The full command would be:

    make_nexus.pl -d <indata> -t <outtree> > <outdata.nex>

## Running an analysis

To run an analysis like this, we have to do the following steps:

1. install a Quad version of BayesTraits. This has higher precision to prevent underflows.
2. open the program, i.e. `BayesTraitsV2_OpenMP_Quad <tree.nex> <data.tsv> < restrictions.txt`

## Post-analysis processing

Once the analysis is completed we will have a large file with samples of rates from the Q
matrix and samples of states at the various internal nodes. As far as I know right now we
don't have to do any hypothesis testing of the rates (e.g. we think it went from this to 
that more so than vice versa), rather, we will want to have estimates for the interior 
nodes and the root. Presumably these will have to be visualized using likelihood pies and
colored branches. Perhaps we will have some use out of the earlier work done for 
[naturalis/asterid-phylo-comp](http://github.com/naturalis/asterid-phylo-comp).
