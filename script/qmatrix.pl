#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use List::Util 'sum';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity = WARN;
my @assoc;
my $logfile;
my $statesfile;
my $burnin;
GetOptions(
	'verbose+'     => \$verbosity,
	'assoc=s'      => sub { my $string = pop; @assoc = split /,/, $string },
	'logfile=s'    => \$logfile,
	'statesfile=s' => \$statesfile,
	'burnin=i'     => \$burnin,
);

# instantiate helper object
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read states file
$log->info("going to read states codes from $statesfile");
my %decode;
{
	open my $fh, '<', $statesfile or die $!;
	while(<$fh>) {
		chomp;
		my ( $v, $k ) = split /\t/, $_;
		my @mask = split //, $v;
		my $code = '';
		for my $i ( 0 .. $#mask ) {
			$code .= $assoc[$i] if $mask[$i];
		}
		$code = '-' if not $code;
		$decode{$k} = $code;
	}
}

# instantiate matrix
my $count = scalar keys %decode;
$log->info("going to instantiate $count x $count rate matrix");
my $i = 0;
my %states = map { $_ => $i++ } sort { $a cmp $b } values %decode;
my @matrix;
for my $j ( 0 .. $count - 1 ) {
	my @row;
	for my $k ( 0 .. $count - 1 ) {
		push @row, [];
	}
	push @matrix, \@row;
}

# read the log file
$log->info("going to read log file $logfile");
my ( @header, @indices );
open my $fh, '<', $logfile or die $!;
while(<$fh>) {
	chomp;
	
	# parse the data
	if ( @header and @indices ) {
		my @data = split /\t/, $_;
		$log->info("Parsing iteration: ".$data[0]);
		for my $index ( @indices ) {
			my $rate = $data[ $index->[0] ];
			my $i = $index->[1];
			my $j = $index->[2];
			push @{ $matrix[$i]->[$j] }, $rate;		
		}	
	}	
	
	# parse the header	
	if ( /^Iteration\b/ ) {
		$log->info("Parsing MCMC results header");
		@header = split /\t/, $_;
		for my $i ( 0 .. $#header ) {
			if ( $header[$i] =~ /^q(.)(.)$/ ) {
				my ( $code_in, $code_out ) = ( $1, $2 );
				push @indices, [
					$i, # column number
					$states{ $decode{ $code_in } },  # single letter => string => index
					$states{ $decode{ $code_out } }, # single letter => string => index				
				];
			}		
		}
	}
}

# print results
$log->info("Averaging rates, formatting output table");
my @states = sort { $a cmp $b } values %decode;
print join( "\t", '', @states ), "\n";
for my $i ( 0 .. $#states ) {
	print $states[$i], "\t";
	for my $j ( 0 .. $#states ) {
		if ( $i == $j ) {
			print '-';
		}
		else {
			my @q = @{ $matrix[$i]->[$j] };
			my $q;
			eval { $q = sum(@q)/@q };
			if ( $@ ) {
				warn $states[$i], ' => ', $states[$j];
			}
			if ( $q == 0 ) {
				print 'X';
			}
			else {
				print $q;
			}
		}
		print $j == $#states ? "\n" : "\t";
	}
}

