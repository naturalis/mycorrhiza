# mycorrhiza
Data and scripts to analyze associations between land plants and mycorrhiza

- data: contains verbatim input data and pruned/converted versions thereof
- script: contains conversion scripts

## restricting the number of transitions, the general idea

The first attempt is as follows: how about we try to treat every permutation of associations
as a separate state in a multistate analysis. Nice idea, except we end up with a very large
Q matrix. We can reduce the number of parameters in the following ways:

1. we only take the empirically observed combinations of observations, not all permutations
2. we disallow transitions where more than one association is gained or lost instantaneously
3. we then do a RJ-MCMC analysis to further reduce the Q matrix.

## preparing the input data

To prepare our input data, we have to do these steps:

1. First we make the raw input for BayesTraits/MultiState using the script `make_ms_input.pl`.
   Make sure that the data with associations is in the same format as 
   HostFungusAssociations.txt or TableS1.txt. The key here is that each data line has the 
   taxon name, some whitespace, and then a sequence of associations, with or without 
   spaces in it. For each line, the first word is matched against the tips in the tree, 
   any lines that don't match anything are assumed to be headers or footers and are 
   ignored. When this happens, a warning is emitted by `make_ms_input.pl`, as follows:
   `putative taxon '$taxon' not in tree, ignoring (could also be table header)`
2. Then we create the BayesTraits/MultiState commands for restricting the transitions as
   per the general idea described above. These commands will also ensure that the run is
   done using reversible jump MCMC. Whether or not you use a hyperprior depends on whether
   the script `make_restrictions.pl` was invoked with the `--hyper` flag. It is probably
   a good idea to do this.
   
Once this is done we should have a tree file in Nexus format, a data file in tab-separated
spreadsheet format, and a text file with the restriction commands. You can now run the
analysis, as per the instructions below.

If you want to explore your data in Mesquite you can run the `make_nexus.pl` script. 
This script expects your data to be formatted with a header that enumerates all state 
symbols between parentheses, like the first line in HostFungusAssociations.txt and 
TableS1.txt

## running an analysis

To run an analysis like this, we have to do the following steps:

1. install a Quad version of BayesTraits. This has higher precision to prevent underflows.
2. open the program, i.e. `BayesTraitsQuad <tree> <data>`
3. select 'Multistate'
4. select 'MCMC'
5. specify RJ priors, e.g. `RevJump exp 10` or `RJHP exp 0 100` (question: which one?)
6. paste the restrictions from `data/*/restrictions.txt` into the program
7. `run`
