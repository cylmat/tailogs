#!/usr/bin/env perl

use strict;
use warnings;

my %HoH = ( 
  flintstones => { 
    husband => "fred", 
    pal => "barney", 
  }, 
  jetsons => { 
    husband => "george", 
    wife => "jane", 
    "his boy" => "elroy", 
    # Key quotes needed. 
  }, 
  simpsons => { 
    husband => "homer", 
    wife => "marge", 
    kid => "bart", 
  }, 
); 

$HoH{ mash } = { 
  captain => "pierce", 
  major => "burns", 
  corporal => "radar", 
}; 

$HoH{flintstones}{wife} = "wilma"; 

for my $family ( keys %HoH ) { 
  #print "$family: "; 
  for my $role ( keys %{ $HoH{$family} } ) { 
    #print "$role=$HoH{$family}{$role} "; 
  } 
  #print "\n"; 
} 

my %HoA = ( 
  flintstones => [
    "fred", 
    "barney"
  ], 
  jetsons => [
    "george", 
    "jane", 
    "elroy"
  ], 
  simpsons => [ 
    "homer", 
    "marge", 
    "bart"
  ]
); 

for my $family ( sort keys %HoA ) {
  print "$family: "; 
  for my $role ( @{ $HoA{$family} } ) {
    #print "$role ";
  }
  foreach ( @{ $HoA{$family} } ) { 
    #print "-$_ ";
  }
  while (my ($index, $elem) = each @{ $HoA{$family} }) {
    print "$index $elem ";
  }
  print "\n"; 
} 
