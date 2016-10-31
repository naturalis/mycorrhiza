# This file is meant to be sourced so that that root states and rates 
# to restrict are part of the environment
export STATES="H G D E"

# between 2016-09-27 and 2016-10-31 the multistate coding has changed,
# below is the original => new mapping
# qBA => qGE, qDC => qHD, qEI => qBC, qFK => qIJ, qGH => qAF
export RATES="qGE qHD qBC qIJ qAF"
