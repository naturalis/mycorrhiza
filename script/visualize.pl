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
use Color::Spectrum qw(hsi2rgb rgb2hsi);

# process command line arguments
my $verbosity = WARN;
my ( @assoc, $logfile, $treefile, $statesfile, $datafile, $width, $height, $burnin );
GetOptions(
	'verbose+' => \$verbosity,
	'assoc=s'  => sub { my $string = pop; @assoc = split /,/, $string },
	'tree=s'   => \$treefile,
	'states=s' => \$statesfile,
	'log=s'    => \$logfile,
	'data=s'   => \$datafile,
	'width=i'  => \$width,
	'height=i' => \$height,
	'burnin=i' => \$burnin,
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
	'-mode'   => 'phylo',
	'-tree'   => $tree,
	'-node_radius' => 12,
	'-pie_colors'  => make_colors(),
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
		$tip->set_font_size(8);
		$tip->set_radius(0);		
	}
}

# done?
print $draw->draw;

sub make_colors {
	my $spec = Color::Spectrum->new;

	# generate as many colors, evenly-spaced over the spectrum between red and fuchsia,
	# as there are associations. convert these to HSI so that we can then average over
	# them to mix colors for multiple associations
	my @primaries;
	for my $c ( $spec->generate( scalar(@assoc), '#FF0000', '#FF00FF' ) ) {
		$c =~ s/^#//;
		push @primaries, [ rgb2hsi( map { hex() / 255 } unpack( 'a2a2a2', $c ) ) ];
	}	

	# read the states file
	open my $fh, '<', $statesfile or die $!;
	while(<$fh>) {
		chomp;
		my ( $v, $k ) = split /\t/, $_;
		
		# split bit mask, combine all h/s/i values for the primaries that appear
		my @mask = split //, $v;
		my ( @h, @s, @i );
		my $key = '';
		for my $i ( 0 .. $#mask ) {
			if ( $mask[$i] ) {
				push @h, $primaries[$i]->[0];
				push @s, $primaries[$i]->[1];
				push @i, $primaries[$i]->[2];
				$key .= $assoc[$i];
			}
		}
		$key = '-' if not $key;
		$decode{$k} = $key;
		if ( @h ) {
			$color{$key} = sprintf "#%02X%02X%02X",
				map { int( $_ * 255 +.5) } hsi2rgb( sum(@h)/@h, sum(@s)/@s, sum(@i)/@i );
        }
        else {
        	$color{$key} = "#000000";
        }
	}
	$log->info("Colors:\n".Dumper(\%color));
	$log->info("Codes:\n".Dumper(\%decode));
	return \%color;
}