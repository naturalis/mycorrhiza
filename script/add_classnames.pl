#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Treedrawer;
use Bio::Phylo::IO qw'parse_tree unparse';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

# Process command line arguments
my ( $csv, $treefile );
GetOptions(
	'csv=s'  => \$csv,
	'tree=s' => \$treefile,
);

# Read tree file
my $tree = parse_tree(
	'-format' => 'newick',
	'-handle' => $treefile,
);

# Read class.csv, attach class names to tips
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

# Carry class names from tips to root
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

# Need to attach the NHX namespace
$tree->set_namespaces( 'nhx' => _NS_NHX_ );

# Find monophyletic class names from root to tips
$tree->visit_depth_first(
	'-pre' => sub {
		my $node = shift;
		if ( my $class = $node->get_generic('class') ) {
			if ( my $parent = $node->get_parent ) {
				my $pclass = $parent->get_generic('class') || {};
				if ( scalar(keys(%$class)) == 1 && scalar(keys(%$pclass)) > 1 ) {
					my ($name) = keys %$class;
					$node->set_meta_object( 'nhx:class' => $name );
					warn $name;
				}
			}
		}	
	}
);

# Remove generic annotations to remove NHX serialization
$tree->visit(sub{shift->set_generic('class'=>undef)});

# Write to New Hampshire eXtended
print unparse(
	'-phylo'  => $tree,
	'-format' => 'nhx',
);
