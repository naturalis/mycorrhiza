The subdirectories below this directory contain different rootings of the same tree. 
The same comparative analyses on the same data are to be performed for each rooting. 
The directory names correspond with the following topologies:

- `Abasal2` = (Anthocerotophyta, (rest)): Hornworts basal.
- `Mbasal2` = (Marchantiophyta, (rest)): Liverworts basal.
- `Tbasal` = (Tracheophyta, (rest)): Vascular plants basal; mosses, hornworts and liverworts in a monophyletic group.
- `ATxMB2` = ((Anthocerotophyta,Tracheophyta),(Marchantiophyta,Bryophyta))

These four different topologies are rearrangements at the base of the tree that reflect
different opinions about how land plants are supposed to be rooted. However, the consensus 
among plant systematists is that `Mbasal2` is the best supported rooting.

Within each directory, the analysis is run by issuing the following command:

    BayesTraitsV2_OpenMP_Quad ${ROOTING}.dnd.nex.btin.nex TableS1.tsv < restrictions.txt

In other words, the tree file that is used is in each case the name of the directory (example: Mbasal2)
with the extension `.dnd.nex.btin.nex`. The data file is a tab-separated table whose eleven observed 
states are coded using letters (A..K). Each letter corresponds to a combination of presences/absences of 
symbiotic relationships with different taxa of mycorrhiza. The mapping between letter and presence/absence 
pattern is defined in the file `states.tsv` in each directory.

The file `restrictions.txt` shows the commands that are executed by BayesTraits. These include:
- node/MRCA definitions for all nodes so that their sampled states are reported in the log and can,
  once the analyses are done, be used to create a pie chart with the different states for each node;
- restrictions because we disallow transitions where more than 1 gain and/or loss happens simultaneously;
- the commands to do an RJ-MCMC multistate analysis on four cores, running for 10 million generations.
