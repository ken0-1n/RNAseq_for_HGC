#! /usr/loca/bin/perl
#
# Copyright Human Genome Center, Institute of Medical Science, the University of Tokyo
# @since 2012
#

use strict;
use warnings;

my $tag = $ARGV[0];

if($tag =~ /[^\w:-]/ ){
  print "TAG : " . $tag . "\n";
  print "Please use only letters(a-z A-Z), numbers(0-9), underbar(_), hyphen(-) or colon(:) on TAG's parameter." . "\n";
  exit 1;
}

