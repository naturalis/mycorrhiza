#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Statistics::R;
use List::Util qw'min max';

my @logs = @ARGV;
my $R = Statistics::R->new;

my @names;
{
	my $i = 0;
	VARNAMES: while(1) {
		my @c;
		for my $j ( 0 .. $#logs ) {
			push @c, substr $logs[$j], $i, 1;
		}
		my %c = map { $_ => 1 } @c;
		if ( scalar(keys(%c)) != 1 ) {
			for my $j ( 0 .. $#logs ) {
				$names[$j] .= $c[$j] if $c[$j];
			}	
		}
		$i++;
		my ($longest) = sort { length($b) <=> length($a) } @logs;
		last VARNAMES if $i == length($longest);
	}
}

my $minIter = 1;
my $maxIter = 0;
my $minLh   = 0;
my $maxLh   = 0;
for my $i ( 0 .. $#logs ) {
	my $data = read_log($logs[$i]);
	$R->set( $names[$i], $data );
	$maxIter = scalar(@$data) if scalar(@$data) > $maxIter;
	my $min  = min @$data;
	my $max  = max @$data;
	$minLh   = $min if $min < $minLh;
	$maxLh   = $max if $max > $maxLh or $maxLh == 0;
}

my $n = scalar(@logs);
my $iterations = [ $minIter .. $maxIter ];
$R->set( 'iterations', $iterations );
$R->set( 'xminmax', [ $minIter, $maxIter ] );
$R->set( 'yminmax', [ $minLh,   $maxLh   ] );
$R->set( 'names', \@names );
$R->run(q`xrange <- range(xminmax)`);
$R->run(q`yrange <- range(yminmax)`);
$R->run(q`plot(xrange, yrange, type="n", xlab="Iterations", ylab="Likelihood")`);
$R->run(qq`colors <- rainbow($n)`);
$R->run(qq`plotchar <- seq(18,18+$n,1)`);

for my $i ( 0 .. $#names ) {
	my $ri = $i + 1; # 1-based indexing
	my $name = $names[$i];
	$name =~ s/"//g;
	my $command = "lines(iterations, $name, type=\"l\", lwd=1.5, lty=1, col=colors[$ri])";
	$R->run($command);
}
$R->run(q`legend(xrange[1], yrange[2], names, cex=0.8, col=colors, lty=1, title="Hypothesis")`);
system('open Rplots.pdf');

sub read_log {
	my $file = shift;
	my @Lh;
	my $iterflag;
	open my $fh, '<', $file or die $!;
	while(<$fh>) {
		chomp;
		if ( $iterflag ) {
			my ( $i, $Lh ) = split /\t/, $_;
			push @Lh, $Lh;
		}
		$iterflag++ if /^Iteration\b/;
	}
	return \@Lh;
}