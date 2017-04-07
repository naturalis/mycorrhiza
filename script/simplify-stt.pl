#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use List::Util 'sum';

# process command line arguments
my $rootage = 549.3475;
my $window  = 50;
my $sttfile;
GetOptions(
	'sttfile=s' => \$sttfile,
	'rootage=f' => \$rootage,
	'window=f'  => \$window,
);

# read table
my ( @values, @header, $scale, $cols );
open my $fh, '<', $sttfile or die $!;
while(<$fh>) {
	chomp;
	my @fields = split /\t/, $_;
	if ( $fields[0] ne 'raw_age' ) {
		if ( not defined $scale ) {
			$scale = $fields[0] / $rootage;
			$cols = $#fields;
		}
		my $age = $fields[0] / $scale;
		my $index = int( $age / $window );
		$values[$index] = [] if not $values[$index];
		push @{ $values[$index] }, \@fields;
	}
	else {
		print join( "\t", @fields ), "\n";
	}
}

for my $i ( 0 .. $#values ) {
	print $i, "\t";	
	for my $j ( 1 .. $cols ) {
		my @v;
		for my $row ( @{ $values[$i] } ) {
			push @v, $row->[$j];
		}
		if ( @v ) {
			print (sum(@v)/scalar(@v));
		}
		else {
			print 'NA';
		}
		$j == $cols ? print "\n" : print "\t";
	}
}




