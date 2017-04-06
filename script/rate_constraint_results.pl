#!/usr/bin/perl

my $dir = shift || '../data/2017-03-06';
my %results;

# iterate over rootings
opendir my $odh, $dir or die $!;
while( my $oe = readdir $odh ) {
	next if $oe =~ /^\.\.?$/;
	if ( -d "${dir}/${oe}" ) {
		my $rooting = $oe;
		my $file = "${dir}/${oe}/states.tsv";		
		my %rate;
		open my $ofh, '<', $file or die "Problem opening $file: $!";
		while(<$ofh>) {
			chomp;
			my ( $value, $key ) = split /\t/, $_;
			$rate{$key} = $value;
		}
		
		# iterate over runs
		my %rates = ( '0001' => [], '0010' => [], '0100' => [], '1000' => [] );
		for my $run ( qw(run1 run2 run3) ) {
			opendir my $idh, "${dir}/${oe}/${run}" or next;
			while( my $ie = readdir $idh ) {
				next if $oe =~ /^\.\.?$/;
			
				# grab Stones file
				if ( $ie =~ /\.qH(.)\.Stones\.txt/ ) {
					my $r = $1;
					my $mlnL;
					open my $ifh, '<', "${dir}/${oe}/${run}/${ie}" or die $!;
					while(<$ifh>) {
						chomp;
						my @fields = split /\t/, $_;
						$mlnL = $fields[1] if $fields[0] eq 'Log marginal likelihood:';
					}
					push @{$rates{$rate{$r}}}, $mlnL;
				}
			}
		}
		$results{$rooting} = \%rates;
	}
}

# print header
print "Rooting\tConstraint-ABGM\tLh-run1\tLh-run2\tLh-run3\n";
for my $Rooting ( keys %results ) {
	for my $Constraint ( keys %{ $results{$Rooting} } ) {
		my @rates = @{ $results{$Rooting}->{$Constraint} };
		print "${Rooting}\t${Constraint}\t@rates\n";
	}
}
