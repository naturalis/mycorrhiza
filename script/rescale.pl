#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use List::Util 'sum';
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my $verbosity = WARN;
my ( $target, $intree );
GetOptions(
	'target=f' => \$target,
	'intree=s' => \$intree,
	'verbose+' => \$verbosity,	
);

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read tree
$log->info("going to read tree from $intree");
my $proj = parse(
	'-format' => 'nexus',
	'-file'   => $intree,
	'-as_project' => 1,
);
my ($tree) = @{ $proj->get_items(_TREE_) };

# calculate scaling factor
$log->info("going to calculate scaling factor");
my @lengths;
$tree->visit(sub{ 
	my $n = shift;
	push @lengths, $n->get_branch_length unless $n->is_root;
});
my $mean  = sum(@lengths) / scalar(@lengths);
my $scale = $target / $mean;
$tree->multiply($scale);

# report results
$log->info("average branch length of input is $mean (n=".scalar(@lengths).")");
$log->info("scaling factor is $scale");
print $proj->to_nexus;