#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use List::Util 'sum';
use Bio::Phylo::Factory;
use Bio::Phylo::Treedrawer;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my $verbosity = WARN;
my $mode = 'clado';
my %config = ( 'radius' => 12 );
my ( @assoc,$logfile,$treefile,$statesfile,$datafile,$taxafile,$width,$height,$burnin );
GetOptions(
	'verbose+' => \$verbosity,
	'assoc=s'  => sub { my $string = pop; @assoc = split /,/, $string }, # fungal taxa
	'tree=s'   => \$treefile, # input tree in nexus format
	'states=s' => \$statesfile, # states.tsv file
	'log=s'    => \$logfile,
	'data=s'   => \$datafile,
	'width=i'  => \$width,
	'height=i' => \$height,
	'burnin=i' => \$burnin,
	'mode=s'   => \$mode,
	'config=s' => \%config,
	'taxa=s'   => \$taxafile,
);

# these are populated when make_colors() is invoked
my %color; # association string (A/B/G/M) to color hex code
my %decode; # single letter code to association string

# instantiate helper objects
my $fac  = Bio::Phylo::Factory->new(
	'node' => 'Bio::Phylo::Forest::DrawNode',
	'tree' => 'Bio::Phylo::Forest::DrawTree',
);
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);
$log->info("going to read nexus tree from $treefile");
my ($tree) = @{ parse(
	'-format'     => 'nexus',
	'-file'       => $treefile,
	'-as_project' => 1,
	'-factory'    => $fac,
)->get_items(_TREE_) };
my $draw = Bio::Phylo::Treedrawer->new(
	'-format' => 'svg',
	'-width'  => $width,
	'-height' => $height,
	'-shape'  => 'radial',
	'-mode'   => $mode,
	'-tree'   => $tree,
	'-padding'      => 400,
	'-branch_width' => $config{'width'},
	'-node_radius'  => $config{'radius'},
	'-pie_colors'   => make_colors(),
);

# read bayestraits log file
my ( %node, @indices );
open my $fh, '<', $logfile or die $!;
LINE: while(<$fh>) {
	chomp;
	
	# parse the data
	if ( @indices ) {
		my @data = split /\t/, $_;
		next LINE if $data[0] < $burnin;
		$log->info("reading iteration ".$data[0]);
		for my $i ( @indices ) {
			my $p = $data[ $i->[0] ]; # probability
			my $n = $node{ $i->[1] }; # node object
			my $s = $decode{ $i->[2] }; # state, decoded to assoc string
			
			# attach to node
			my $pie = $n->get_generic('pie') || {};
			$pie->{$s} = [] if not $pie->{$s};
			push @{ $pie->{$s} }, $p; # we will average this in the end
			$n->set_generic( 'pie' => $pie );
		}
	}
	
	# apply node names to MRCAs of putatively subtended tips
	if ( /^\t(Node\d+)Tag\t(\d+)\t(.+)$/ ) {
		my ( $name, $exp, $taxa ) = ( $1, $2, $3 );
		my @tips = map { $tree->get_by_name($_) } grep { /\S/ } split /\s+/, $taxa;
		if ( $exp != scalar(@tips) ) {
			$log->error("found ".scalar(@tips)." tips but expected $exp");
		}
		else {
			my $mrca = $tree->get_mrca(\@tips);
			$node{$name} = $mrca;
			$log->debug("found node $name");
		}
	}
	
	# start reading the iterations once this flag has been set
	if ( /^Iteration\b/ ) {
		$log->info("Found ".scalar(keys(%node))." nodes");
		$log->info("Starting data section, parsing header");
		my @header = split /\t/, $_;
		for my $i ( 0 .. $#header ) {
			if ( $header[$i] =~ /^(Node\d+) P\((.)\)/ ) {
				my ( $node, $state ) = ( $1, $2 );
				push @indices, [ $i, $node, $state ];
			}
		}
	}
}

# calculate the averages, apply MAP colors
for my $n ( values %node ) {
	if ( my $pie = $n->get_generic('pie') ) {
		for my $k ( keys %$pie ) {
			my @v = @{ $pie->{$k} };
			$pie->{$k} = sum(@v)/@v;			
		}
		my ($map) = sort { $pie->{$b} <=> $pie->{$a} } keys %$pie;
		$n->set_branch_color( $color{$map} );
		$n->set_node_outline_colour( $color{$map} );
	}
}

# remove the pies, if requested
if ( $config{'pies'} eq 'no' ) {
	for my $n ( values %node ) {
		$n->set_generic( 'pie' => undef );
	}
}

# apply colors for terminal branches
{
	open my $fh, '<', $datafile or die $!;
	while(<$fh>) {
		chomp;
		my ( $taxon, $code ) = split /\t/, $_;
		my $tip = $tree->get_by_name($taxon);
		$tip->set_branch_color( $color{ $decode{ $code } } );
		$tip->set_font_style('Italic');
		$tip->set_font_face('Verdana');
		$tip->set_font_size(10);
		$tip->set_radius(0);		
	}
}

# apply higher taxa, if provided
if ( $taxafile and -e $taxafile ) {
	my %taxa;
	open my $fh, '<', $taxafile or die $!;
	while(<$fh>) {
		chomp;
		my ( $species, $taxon ) = split /\t/, $_;
		$taxa{$taxon} = [] if not $taxa{$taxon};
		if ( my $tip = $tree->get_by_name($species) ) {
			push @{ $taxa{$taxon} }, $tip;
		}
		else {
			$log->warn("Couldn't find $species in $tree");
		}
	}
	for my $taxon ( keys %taxa ) {
		my $mrca = $tree->get_mrca( $taxa{$taxon} );
		$mrca->set_clade_label( $taxon );
		$mrca->set_clade_label_font({
			'-face' => 'Verdana',
			'-size' => 40,
		});
	}
	$draw->set_text_width( 10 );
}

# remove the tip labels, if requested
if ( $config{'tips'} eq 'no' ) {
	for my $tip ( @{ $tree->get_terminals } ) {
		$tip->set_name('');
	}
}

# done?
print $draw->draw;

sub make_colors {

	# read the states file
	open my $fh, '<', $statesfile or die $!;
	while(<$fh>) {
		chomp;
		my ( $v, $k ) = split /\t/, $_;
		
		# split bit mask, combine all h/s/i values for the primaries that appear
		my @mask = split //, $v;
		my $key = '';
		for my $i ( 0 .. $#mask ) {
			if ( $mask[$i] ) {
				$key .= $assoc[$i];
			}
		}
		$key = '-' if not $key;
		$decode{$k} = $key;
	}
	
	# XXX alert: these colors are now hard-coded to match those in the D3
	# visualization in results/d3.html
	%color = (
		"-"   => "#d16115",
		"A"   => "#e0cf2c",
		"AB"  => "#dbdcad",
		"ABG" => "#5a5f1a",
		"B"   => "#95a41b",
		"BG"  => "#5d919e",
		"G"   => "#6ad6f6",
		"GM"  => "#21bff3",
		"M"   => "#18558a",
	);
	$log->info("Colors:\n".Dumper(\%color));
	$log->info("Codes:\n".Dumper(\%decode));
	return \%color;
}