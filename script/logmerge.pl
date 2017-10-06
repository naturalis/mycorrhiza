#!/usr/bin/perl
use strict;
use warnings;
use List::Util 'sum';

my @logs = @ARGV;

# open handles
my %handle;
for my $log ( @logs ) {
	open my $fh,'<', $log or die $!;
	$handle{$log} = $fh;
}

# forward all handles to the /^Iteration\b/ line
for my $handle ( values %handle ) {
	SEEK: while ( ! eof($handle) ) {
		if ( defined( $_ = <$handle> ) ) {
			last SEEK if /^Iteration\b/;
		}
	}
}

MERGE: while(1) {
	my @records;
	my $length;
	for my $handle ( values %handle ) {
		if ( ! eof($handle) ) {
			my $line = readline($handle);
			chomp($line);
			my @fields = split /\t/, $line;
			push @records, \@fields;
			$length = $#fields;
		}
		else {
			last MERGE;
		}
	}
	my @merge;
	for my $i ( 0 .. $length ) {
		my @values;
		my $istext;
		for my $r ( @records ) {
			my $val = $r->[$i];
			$istext = $val if $val =~ /^'/;
			push @values, $val;
		}
		if ( $istext ) {
			push @merge, $values[0];
		}
		else {
			push @merge, ( sum(@values)/scalar(@values) );
		}
	}
	print join( "\t", @merge ), "\n";
}