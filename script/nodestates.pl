#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# process command line arguments
my ( $log, $node, $states );
GetOptions(
	'log=s'    => \$log,
	'node=s'   => \$node,
	'states=s' => \$states,	
);

my %state;
{
	open my $fh, '<', $states or die $!;
	while(<$fh>) {
		chomp;
		my ( $v, $k ) = split /\s+/, $_;
		$state{$k} = $v;
	}
}

{
	my ( @indices, @header );
	open my $fh, '<', $log or die $!;
	while(<$fh>) {
		chomp;
		if ( @indices ) {
			my @line = split /\t/, $_;			
			print join( "\t", @line[@indices] ), "\n";
		}
		if ( /^Iteration\b/ and not @indices ) {
			@header = split /\t/, $_;
			for my $i ( 0 .. $#header ) {
				if ( $header[$i] =~ /$node\s/ ) {
					push @indices, $i;
				}		
			}
			my @s;
			for my $i ( @indices ) {
				 if ( $header[$i] =~ /\((.)\)/ ) {
				 	my $s = $1;
				 	push @s, $state{$s};
				 }
			}			
			print join( "\t", @s ), "\n";
		}
	}
}