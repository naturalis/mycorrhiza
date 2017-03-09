README.md
=========
Over the course of the project, the analysis has been developed and the input files have
been refined to the state that this directory is in. Here now follows a brief explanation
of all the moving parts.


Input files
-----------
This directory contains a number of hand-crafted input files, itemized here.

### [HostFungusAssociations.txt](HostFungusAssociations.txt)

The original character state matrix by Frida, in a non-standard, pseudo-tabular format.

### [HostFungusAssociations.txt.tsv](HostFungusAssociations.txt.tsv)

The character matrix recoded for input in BayesTraits. This has undergone the following 
modifications:
 
1. the sequences of four 0/1 switches that code for the absence/presence of associations
   with the four major groups of mycorrhiza (A, B, G, and M) have been recoded into single
   letter codes. The mapping between these is in [states.tsv](states.tsv). 
2. the updated table omits two species (_Lobelia dortmanna_ and _Pinus contorta_) that 
   had singleton observations (1010 and 1101) that needlessly complicated the Q matrix.
   
### [Mbasal_mod1.bt.rescaled.nex](Mbasal_mod1.bt.rescaled.nex)

The consensus tree file of a BEAST run with the preferred rooting (this rooting is coded 
as `Mbasal` with this project). This tree has been modified further to remove the two taxa 
that were also removed from the character state matrix: _Lobelia dortmanna_ and 
_Pinus contorta_.

Shell scripts and command files
-------------------------------
The following ephemeral shell scripts were created (or generated) within this directory.

### [dataprep.sh](dataprep.sh)

This shell script invokes a number of Perl scripts that are in the script folder at the 
top level of this project. The first invocation, of 
[make_ms_input.pl](../../script/make_ms_input.pl) recodes Frida's input table into the
single-character states for BayesTraits and spits out the state mapping (see above). The
script then invokes [make_restrictions.pl](../../script/make_restrictions.pl) to create
command files for BayesTraits (which are simply piped into STDIN of the executable). The
invocations are first done four times to constrain the analyses to disallow the following 
transitions, respectively: 

- `0000 => 0001` - [constrained.qHG.0.txt](constrained.qHG.0.txt)
- `0000 => 0010` - [constrained.qHD.0.txt](constrained.qHD.0.txt)
- `0000 => 0100` - [constrained.qHB.0.txt](constrained.qHB.0.txt)
- `0000 => 1000` - [constrained.qHI.0.txt](constrained.qHI.0.txt)
  
For each of these, the analysis does a stepping stone sampler to approximate the marginal 
likelihood given the constrained Q matrix. In the final invocation, which produces the
command file [unconstrained.txt](unconstrained.txt), the marginal likelihood is 
approximated given an unconstrained Q matrix. We can thus determine by elimination which 
initial transition from no association to the first one is best supported by the present 
evidence, because that will be the one whose marginal likelihood is most affected by the
constraint (spoiler: this appears to be `0000 => 0001`). Whether the constraint has a 
significant effect is indicated by the test statistic, i.e. the log Bayes factor, whose
calculation and interpretation for the present case is discussed on page 14 of the 
[BayesTraits manual](http://www.evolution.rdg.ac.uk/BayesTraitsV3/Files/BayesTraitsV3.Manual.pdf).

Finally, the dataprep.sh script generates three simple shell scripts ([run1.sh](run1.sh),
[run2.sh](run2.sh), and [run3.sh](run3.sh)) that do the actual invocation of BayesTraits 
(i.e. loading the tree, the data, and piping the command file into its STDIN) in 
triplicate. This is because the analyses is, like any Markov chain, a process that can 
fail to generate a good posterior sample so it is generally advisable to do this multiple
times to detect artefacts / bad runs. The generated shell scripts  manage that all output 
files end up in their respective results directories ([run1](run1), [run2](run2) and 
[run3](run3)). For the Bayes factor calculations, the marginal likelihoods are printed on 
the last lines of the *.Stones.txt files. The (very large, compressed) *.log.gz files 
contain the posterior samples of all the internal node states and transition rates that 
BayesTraits encountered.

Final summaries
---------------

### [qmatrix.run2.unconstrained.tsv](qmatrix.run2.unconstrained.tsv)

This table shows the Q matrix as extracted from 
[the unconstrained log of the second run](run2/HostFungusAssociations.txt.unconstrained.log.gz),
out of which the matrix was extracted using the script [qmatrix.pl](../../script/qmatrix.pl).

