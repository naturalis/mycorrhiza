#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# process command line arguments
my $states;
GetOptions(
	'states=s' => \$states,
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
