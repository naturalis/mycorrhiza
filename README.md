# mycorrhiza
Data and scripts to analyze associations between land plants and mycorrhiza

- data: contains verbatim input data and pruned/converted versions thereof
- script: contains conversion scripts

The first attempt is as follows: how about we try to treat every permutation of associations
as a separate state in a multistate analysis. Nice idea, except we end up with a very large
Q matrix. We can reduce the number of parameters in the following ways:

1. we only take the empirically observed combinations of observations, not all permutations
2. we disallow transitions where more than one association is gained or lost instantaneously
3. we then do a RJ-MCMC analysis to further reduce the Q matrix.

To run an analysis like this, we have to do the following steps:

1. install a Quad version of BayesTraits. This has higher precision to prevent underflows.
2. open the program, i.e. `BayesTraitsQuad <tree> <data>`
3. select 'Multistate'
4. select 'MCMC'
5. specify RJ priors, e.g. `RevJump exp 10` or `RJHP exp 0 100` (question: which one?)
6. paste the restrictions from `data/restrictions.txt` into the program
7. `run`
