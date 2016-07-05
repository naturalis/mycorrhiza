#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# Usage:
# perl make_ms_input.pl -data <indata> -in <tree> -out <tree> -table <outdata>

# process command line arguments
my $verbosity = WARN;
my ( $data_file, $tree_file, $out_data, $out_tree, $help );
GetOptions(
	'data=s'   => \$data_file,
	'in=s'     => \$tree_file,
	'verbose+' => \$verbosity,
	'out=s'    => \$out_tree,
	'table=s'  => \$out_data,
	'h|?'      => \$help,
);

# print usage and quit
if ( $help ) {
	die "Usage:\n\tmake_ms_input.pl -data <indata> -in <tree> -out <tree> -table <outdata>\n"
}

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read tree
$log->info("going to read tree '$tree_file' as nexus");
my $project = parse(
	'-format' => 'nexus',
	'-file'   => $tree_file,
	'-as_project' => 1,
);
my ($tree) = @{ $project->get_items(_TREE_) };
$log->info("read tree '$tree' with ".scalar(@{$tree->get_terminals})." tips");

# read data
my %data;
{
	my @alpha = ( 'A' .. 'Z' );
	my %seen;
	$log->info("going to read tabular data from '$data_file'");
	open my $fh, '<', $data_file or die $!;
	while(<$fh>) {
		chomp;
		my ( $taxon, $states ) = split /\s+/, $_;
		if ( $tree->get_by_name( $taxon ) ) {
			$data{$taxon} = $seen{$states} || ( $seen{$states} = shift @alpha );
		}
		else {
			$log->warn("putative taxon '$taxon' not in tree, ignoring (could also be table header)");
		}
	}
	$log->info("read ".scalar(keys(%seen))." states for ".scalar(keys(%data))." taxa");
	close $fh;
}

# reconcile tree and data
$log->info("going to prune tips without data from tree");
my @prune;
for my $tip ( @{ $tree->get_terminals } ) {
	my $name = $tip->get_name;
	if ( not $data{$name} ) {
		$log->warn("'$name' has no data, pruning");
		push @prune, $name;
	}
}
$tree->prune_tips(\@prune);

# write data output
{
	$log->info("going to write data to '$out_data'");
	open my $fh, '>', $out_data or die $!;
	for my $key ( sort { $a cmp $b } keys %data ) {
		print $fh $key, "\t", $data{$key}, "\n";
	}
	close $fh;
}

# write tree output
{
	$log->info("going to write tree to '$out_tree'");
	open my $fh, '>', $out_tree or die $!;
	print $fh $project->to_nexus( '-translate' => 1 );
	close $fh;
}
