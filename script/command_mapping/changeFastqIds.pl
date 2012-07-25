#! /usr/loca/bin/perl
#$ -S /usr/local/bin/perl
#$ -cwd
#
# Copyright Human Genome Center, Institute of Medical Science, the University of Tokyo
# @since 2012
#

use strict;
use warnings;

my $tag = $ARGV[0];
my $pair_num = $ARGV[1];
my $input  = $ARGV[2];
my $output = $ARGV[3];

open(IN, $input) || die "cannot open $!";
open(OUT, ">" . $output) || die "cannot open $!";

my $num = 1;
while(<IN>) {
    my $bases = <IN>;
    my $plus  = <IN>;
    my $qual  = <IN>;
    print OUT "@". $tag ."_". $num ."/". $pair_num ."\n";
    print OUT $bases;
    print OUT $plus;
    print OUT $qual;
    $num++;
}
close(IN);
close(OUT);

