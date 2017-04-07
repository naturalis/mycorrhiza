#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use List::Util 'sum';
use Bio::Phylo::IO 'parse_tree';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity = WARN;
my $burnin = 500000;
my ( $treefile, $logfile );
GetOptions(
	'verbose+'   => \$verbosity,
	'burnin=i'   => \$burnin,
	'treefile=s' => \$treefile,
	'logfile=s'  => \$logfile,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-class' => 'main',
	'-level' => $verbosity,
);
$log->info("going to read tree $treefile");
my $tree = parse_tree(
	'-format' => 'nexus',
	'-file'   => $treefile,
);

# start parsing the log
$log->info("going to read log $logfile");
my ( %nodes, %header, %states );
open my $fh, '<', $logfile or die $!;
LINE: while(<$fh>) {
	chomp;
	
	# fetch corresponding node
	if ( /^\t(Node\d+)Tag\t\d+\t(.+)$/ ) {
		my ( $tag, $taxa ) = ( $1, $2 );
		my @nodes;
		for my $t ( split /\s/, $taxa ) {
			if ( my $n = $tree->get_by_name($t) ) {
				push @nodes, $n;
			}
			else {
				$log->warn("no $t in $tree");
			}
		}
		my $mrca = $tree->get_mrca(\@nodes);
		$nodes{$tag} = $mrca;
		$log->debug("found node $tag");
		next LINE;
	}
	
	# parse header
	if ( not %header and /^Iteration\t.+$/ ) {
		my @fields = split /\t/, $_;
		$log->info("going to read log file header");
		for my $i ( 0 .. $#fields ) {
			if ( $fields[$i] =~ /^(Node\d+) P\((.)\)$/ ) {
				my ( $tag, $state ) = ( $1, $2 );
				$states{$state} = undef;
				$header{$tag} = [] if not $header{$tag};
				push @{ $header{$tag} }, { 
					'index' => $i, 
					'state' => $state,
				};
			}
		}
		next LINE;
	}
	
	# parse data
	if ( %header ) {
		my @fields = split /\t/, $_;
		my $gen = $fields[0];
		if ( $gen >= $burnin ) {
			$log->debug("processing post-burn-in generation $gen");
			$log->info("reached end of burn-in ($burnin)") if $gen == $burnin;
			for my $node ( keys %nodes ) {
				for my $column ( @{ $header{$node} } ) {
					my $i = $column->{'index'};
					my $s = $column->{'state'};
					my $values = $nodes{$node}->get_generic($s) || [];
					push @{ $values }, $fields[$i];
					$nodes{$node}->set_generic( $s => $values );
				}
			}
		}
		else {
			$log->debug("skipping burn-in generation $gen");
		}
	}
}

# calculate node ages (MYA)
$tree->visit_depth_first(
	'-post' => sub {
		my $node = shift;
		if ( $node->is_terminal ) {
			$node->set_generic( 'age' => 0 );
		}
		else {
			my $fd = $node->get_first_daughter;
			my $bl = $fd->get_branch_length;
			$node->set_generic( 'age' => ( $fd->get_generic('age') + $bl ) );
		}
	}
);

# print results
my @states = keys %states;
print join( "\t", 'age', @states ), "\n";
$tree->visit_depth_first(
	'-pre' => sub {
		my $node = shift;
		my @values = $node->get_generic('age');
		for my $s ( @states ) {
			if ( my $v = $node->get_generic($s) ) {
				push @values, ( sum(@$v)/scalar(@$v) );
			}
			else {
				push @values, 0;
			}
		}
		print join( "\t", @values ), "\n";
	}
);