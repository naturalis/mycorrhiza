#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO 'parse_tree';

# process command line arguments
my ( $states, $tree, $hyper );
my $iterations = -1;
my $cores;
my @fossil;
my @restrict;
my $stones;
GetOptions(
	'states=s'     => \$states,
	'tree=s'       => \$tree,
	'hyper=s'      => \$hyper, # min,max
	'iterations=i' => \$iterations,
	'cores=i'      => \$cores,
	'fossil=s'     => \@fossil,   # tip1,tip2=value
	'restrict=s'   => \@restrict, # qAB=qBA or qAB=0
	'stones=s'     => \$stones,   # min,max
);

# read tree
my $t = parse_tree(
	'-format' => 'nexus',
	'-file'   => $tree,
);

# read states
my %states;
{
	open my $fh, '<', $states or die $!;
	while(<$fh>) {
		chomp;
		my ( $state, $alias ) = split /\s+/, $_;
		$states{$state} = $alias;
	}
}

# print first commands header
print "1\n"; # multistate
print "2\n"; # MCMC
$hyper =~ s/,/ /;
print $hyper ? "RJHP exp $hyper\n" : "RevJump exp 10\n"; # hyperprior drawn from 0..100?

# print node statements
$t->visit_depth_first(
	'-post' => sub {
		my $node = shift;
		my $name = $node->get_internal_name;
		if ( $node->is_terminal ) {			
			$node->set_generic( 'tips' => [ $name ] );
		}
		else {
			my @tips;
			for my $c ( @{ $node->get_children } ) {
				push @tips, @{ $c->get_generic('tips') };
			}
			$node->set_generic( 'tips' => \@tips );
			print "AddMRCA $name $tips[0] $tips[-1]\n";
		}
	}
);

# print restrictions
my @states = keys %states;
for my $i ( 0 .. $#states - 1 ) {
	my @si = split //, $states[$i];
	my $ai = $states{$states[$i]};
	for my $j ( $i + 1 .. $#states ) {
		my $aj = $states{$states[$j]};
		my @sj = split //, $states[$j];
		my $diffs = 0;
		for my $k ( 0 .. $#sj ) {
			$diffs += abs( $si[$k] - $sj[$k] );
		}
		if ( $diffs > 1 ) {
			print "Restrict q${ai}${aj} 0\n";
			print "Restrict q${aj}${ai} 0\n";
		}
	}
}

# print additional restrictions
for my $r ( @restrict ) {
	my ( $rate, $value ) = split /=/, $r;
	print "Restrict ${rate} ${value}\n";
}

# print fossils here
for my $f ( @fossil ) {
	my ( $tips, $value ) = split /=/, $f;
	my @tips;
	for my $tip ( split /,/, $tips ) {
		if ( my $n = $t->get_by_name($tip) ) {
			push @tips, $n;
		}
		else {
			warn "$tip is not in the tree!";
		}
	}
	if ( @tips == 2 ) {
		my $mrca  = $t->get_mrca(\@tips)->get_internal_name;
		my $left  = $tips[0]->get_name;
		my $right = $tips[1]->get_name;
		print "Fossil ${mrca} ${value} ${left} ${right}\n"; 
	}
}

# print closing commands
print "iterations $iterations\n"; # default is infinity, reasonable is 10*10^6
print "cores $cores\n" if defined $cores; # only for multi-core, e.g. OpenMP
if ( $stones ) {
	$stones =~ s/,/ /;
	print "stones $stones\n";
}
print "run\n"; # start sampling
