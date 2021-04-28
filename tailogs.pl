#!/usr/bin/env perl

# https://www.geeksforgeeks.org/perl-warnings-and-how-to-handle-them/

use strict;
use warnings;

# apt-get install -y locales locales-all
# echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale
# print "@{[ %hash ]}";
# foreach my $k (sort keys %config) { print "$k => $config{$k}\n"; }
# while ( ($k,$v) = each %hash ) { print "$k => $v\n"; }
#
#
# my %HoA = ( 
#   flintstones => [
#     "fred", 
#     "barney"
#   ], 
#
# foreach $number ( @numbers ) {
#   for my $family ( sort keys %HoA ) {
#   print "$family: "; 
#   while (my ($index, $elem) = each @{$HoA{$family}}) {
#     print "$index $elem ";
#   }
#   print "\n"; 
#   } 

###################
# Define commands #
###################

use constant TAIL => "/usr/bin/tail";

# for my $family ( sort keys %HoA ) {
#   print "$family: "; 
#   while (my ($index, $elem) = each @{$HoA{$family}}) {
#     print "$index $elem ";
#   }
#   print "\n"; 
# }

sub get_config {
  my %config = ();
  my $filename = "/var/log/apt/history.log";

  $config{'filename'} = $filename;
  my @actual_patterns = [
    "command: msg",
    "install: msg2",
    "txtdate: date time"
  ];
  my @new_pattern = [
    "msg-command",
    "msg2 local",
    "date date time time"
  ];
  @config{'actual_pattern'} = @actual_patterns;
  @config{'new_pattern'} = @new_pattern;

  while (my ($index, $elem) = each @{$config{'actual_pattern'}}) {
    print "$elem\n";
  }
  exit;
  return %config;
}

###########
# PROCESS #
###########

########
# MAIN #
########

sub run_tail(%) {
  my %config = @_;
  
  my @args = ("-n 3");
  push(@args, $config{'filename'});

  my $tail_args = TAIL . " @args";
  #print $tail_args; exit; #DEBUG

  open my $tail_pipe, "-|", $tail_args or die "Error - Could not start tail on $config{'filename'}: $!";
  print while <$tail_pipe>;
}

sub main {
  my %config = get_config();
  run_tail(%config);
}

main();
