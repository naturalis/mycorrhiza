#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my $verbosity = WARN;
my ( $data, $tree );
GetOptions(
	'data=s'   => \$data,
	'tree=s'   => \$tree,
	'verbose+' => \$verbosity,
);

# instantiate factory
my $fac = Bio::Phylo::Factory->new;

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read nexus
$log->info("going to read nexus data from '$tree'");
my $project = parse(
	'-format' => 'nexus',
	'-file'   => $tree,
	'-as_project' => 1,
);
my ($taxa) = @{ $project->get_items(_TAXA_) };

# read data, insert into $matrix
my $matrix = $fac->create_matrix(
	'-type' => 'standard',
	'-taxa' => $taxa,
);
{
	$log->info("going to read data from $data");
	my $header;
	my $to = $matrix->get_type_object;
	open my $fh, '<', $data or die $!;
	LINE: while(<$fh>) {
		chomp;

		# parse header line
		if ( not $header and /\((.+)\)/ ) {
			$header = $1;
			my @charlabels = grep { /\S/ } split /\s/, $header;
			my @statelabels = map { [ qw(absent present) ] } @charlabels;
			$matrix->set_charlabels(  \@charlabels  );
			$matrix->set_statelabels( \@statelabels );
			$log->info("characters: @charlabels");
			next LINE;
		}

		# parse character sequence
		my ( $name, @seq ) = split /\s+/, $_;
		$matrix->insert( $fac->create_datum(
			'-type_object' => $to,
			'-name'        => $name,
			'-taxon'       => $taxa->get_by_name($name),
			'-char'        => \@seq,
		) );

	}
}

# write entire project as nexus for mesquite
$project->insert($matrix);
print $project->to_nexus( '-charstatelabels' => 1 );
