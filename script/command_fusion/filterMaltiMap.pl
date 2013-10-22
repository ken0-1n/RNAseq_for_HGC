#! /usr/local/bin/perl
#
# Copyright Human Genome Center, Institute of Medical Science, the University of Tokyo
# @since 2012
#

use strict;
use warnings;

my $input = $ARGV[0];

my %titleHash = ();
$titleHash{"multi map1"} = 1;
$titleHash{"multi map2"} = 1;

my %titleHashCM = ();
$titleHashCM{"cross map1"} = 1;
$titleHashCM{"cross map2"} = 1;

my %notFiltHash = ();
$notFiltHash{"chr6_apd_hap1"} = 1;
$notFiltHash{"chr6_cox_hap2"} = 1;
$notFiltHash{"chr6_dbb_hap3"} = 1;
$notFiltHash{"chr6_mann_hap4"} = 1;
$notFiltHash{"chr6_mcf_hap5"} = 1;
$notFiltHash{"chr6_qbl_hap6"} = 1;
$notFiltHash{"chr6_ssto_hap7"} = 1;
$notFiltHash{"chr4_ctg9_hap1"} = 1;
$notFiltHash{"chr17_ctg5_hap1"} = 1;
$notFiltHash{"---"} = 1;

my @idxArr = ();
my @idxArrCM = ();

open(IN,$input) || die "cannot open $input";
$_ = <IN>;
s/[\r\n]//g;
my @curRow = split("\t", $_);
for( my $idx=0 ; $idx <= $#curRow ; $idx++ ) {
    if ( exists($titleHash{$curRow[$idx]}) ) {
        push( @idxArr, $idx );
    }
    if ( exists($titleHashCM{$curRow[$idx]}) ) {
        push( @idxArrCM, $idx );
    }
}
close(IN);

my $mmIdx1 = $idxArr[0]; 
my $mmIdx2 = $idxArr[1]; 

my $cmIdx1 = $idxArrCM[0]; 
my $cmIdx2 = $idxArrCM[1]; 

open(IN,$input) || die "cannot open $input";

my $title_line = <IN>;
$title_line =~ s/[\r\n]//g;
print $title_line . "\n";

F_LOOP: while(<IN>) {
  s/[\r\n]//g;
  my @curRow = split("\t", $_);

  my $multi_map1 = $curRow[$mmIdx1];
  my @curCol1 = split(",",$multi_map1);
  foreach my $col ( @curCol1 ) {
    my @chr_pos = split(":", $col);
    next F_LOOP if (not exists($notFiltHash{$chr_pos[0]}));
  }

  my $multi_map2 = $curRow[$mmIdx2];
  my @curCol2 = split(",", $multi_map2);
  foreach my $col ( @curCol2 ) {
    my @chr_pos = split(":", $col);
    next F_LOOP if (not exists($notFiltHash{$chr_pos[0]}));
  }
  
  my $cross_map1 = $curRow[$cmIdx1];
  next F_LOOP if ($cross_map1 > 0);
  
  my $cross_map2 = $curRow[$cmIdx2];
  next F_LOOP if ($cross_map2 > 0);
  
  print $_ . "\n";
}
close(IN);


