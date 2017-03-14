#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use List::Util 'sum';

# process command line arguments
my $burnin = 0.2;
my ( $log, $node, $states );
GetOptions(
	'log=s'    => \$log,    # BayesTraits log file
	'node=s'   => \$node,   # internal node label
	'states=s' => \$states,	# states.tsv
	'burnin=f' => \$burnin, # fraction
);

# read the state mapping
my %state;
{
	open my $fh, '<', $states or die $!;
	while(<$fh>) {
		chomp;
		my ( $v, $k ) = split /\s+/, $_;
		$state{$k} = $v;
	}
}

my ( $linecount, %records, @s );
{
	my ( @indices, @header, $root );
	open my $fh, '<', $log or die $!;
	while(<$fh>) {
		chomp;
		
		# Once @indices has been populated it means we are reading the lines logged
		# during the chain. Print these out and capture them.
		if ( @indices ) {
			$linecount++;
			my @line = split /\t/, $_;			
			print join( "\t", @line[@indices] ), "\n";
			for my $i ( @indices ) {
				push @{ $records{$s[$i]} }, $line[$i];
			}
		}
		
		# Before the chain starts, BayesTraits spits out definitions for all the nodes
		# for which the states will be logged. This section ends with lines where a "tag"
		# is associated with a node using syntax that matches the regular expression 
		# below. If we just keep capturing these statements then the last seen one 
		# will be the root, which we can use as the default node if no other was defined.		
		if ( /^\s+MRCA (Node\d+) Node\d+Tag\s*$/ ) {
			$root = $1;
		}
		
		# Capture the header right before lines logged in the chain.
		if ( /^Iteration\b/ and not @indices ) {
		
			# Use the label of the root node as default if no other provided.
			$node = $root if not $node;
			
			# Iterate over the header to capture the indices of all the columns
			# that log the focal node of interest.
			@header = split /\t/, $_;						
			for my $i ( 0 .. $#header ) {
				if ( $header[$i] =~ /$node\s/ ) {
					push @indices, $i;
				}		
			}
			
			# Parse out the single-character state codes and translate them back 
			# to the bit masks from states.tsv, print out the header.
			for my $i ( @indices ) {
				 if ( $header[$i] =~ /\((.)\)/ ) {
				 	my $s = $1;
				 	$s[$i] = $state{$s};
				 }
				 else {
				 	warn;
				 }
			}
			%records = map { $_ => [] } grep { defined } @s;	
			print join( "\t", grep { defined } @s ), "\n";
		}
	}
}

# print output
print join( "\t", grep { defined } @s ), "\n";
my $startindex = int( $burnin * $linecount );
for my $key ( grep { defined } @s ) {
	my @values = @{ $records{$key} };
	my @postburn = @values[$startindex .. ($linecount-1)];
	my $value = sum(@postburn)/scalar(@postburn);
	print 'AVERAGE', "\t", $key, "\t", sprintf('%.6f',$value), "\n";
}