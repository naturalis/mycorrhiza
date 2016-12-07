#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse_tree';

# process command line arguments
my ( $csv, $treefile );
GetOptions(
  'csv=s'  => \$csv,
  'tree=s' => \$treefile,
);

# Data can be read from url, handle, file or string. 
# This example uses the *DATA pseudo-handle that gives
# access to the contents at the bottom of this file.
my $tree = parse_tree(
	'-format' => 'newick',
	'-file'   => $treefile,
);

# Read classes.csv and attach class names to tips
open my $fh, '<', $csv or die $!;
while(<$fh>) {
	chomp;
	my ( $species, $class ) = split /,/, $_;
	if ( $class ) {
		if ( my $tip = $tree->get_by_name($species) ) {
			$tip->set_generic( 'class' => { $class => 1 } );
		}
	}
}

# Carry over class names from tips to root
$tree->visit_depth_first(
	'-post' => sub {
		my $node = shift;
		if ( my $class = $node->get_generic('class') ) {
			if ( my $parent = $node->get_parent ) {
				my $pclass = $parent->get_generic('class') || {};
				for my $key ( keys %$class ) {
					$pclass->{$key} += $class->{$key};
				}
				$parent->set_generic( 'class' => $pclass );
			}
		}
	}
);

# Identify monophyletic classes from root to tips
$tree->visit_depth_first(
	'-pre' => sub {
		my $node = shift;
		if ( my $class = $node->get_generic('class') ) {
			if ( my $parent = $node->get_parent ) {
				my $pclass = $parent->get_generic('class') || {};
				if ( scalar(keys(%$class)) == 1 && scalar(keys(%$pclass)) > 1 ) {
					my ($name) = keys %$class;
					$node->set_name($name);
					warn $name;
				}
			}
		}	
	}
);

print $tree->to_newick( '-nodelabels' => 1 );
