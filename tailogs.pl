#!/usr/bin/env perl

# https://www.geeksforgeeks.org/perl-warnings-and-how-to-handle-them/

use strict;
use warnings;

# apt-get install -y locales locales-all
# echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale
# print "@{[ %hash ]}";

###################
# Define commands #
###################

sub get_config {
  my %config;
  my $filename = "/var/log/apt/history.log";

  $config{'filename'} = $filename;
  $config{'pattern'} = "log1 log2";
  $config{'new_pattern'} = "alpha5";
   
  return %config;
}

###########
# PROCESS #
###########

########
# MAIN #
########

# param %config
sub run_tail(%) {
  my %config = %_[0];
  #print "@_";
  
  my $tail_cmd = "/usr/bin/tail";
  my @args = ("-n 3");
  push(@args, "");
  my $filename='';

  my $tailcmd_args = "$tail_cmd @args $filename";

  open my $pipe, "-|", $tailcmd_args or die "could not start tail on SampleLog.log: $!";
  print while <$pipe>;
}

sub main {
  my %config = get_config();
  print keys %config;
  exit;
  run_tail(%config);
}

main();
