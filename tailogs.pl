#!/usr/bin/env perl

# https://www.geeksforgeeks.org/perl-warnings-and-how-to-handle-them/

use strict;
use warnings;

###################
# Define commands #
###################

sub dev_config {

}

sub tail {
  open my $pipe, "-|", "/usr/bin/tail", "-f", "/var/log/apt/history.log" or die "could not start tail on SampleLog.log: $!";
  print while <$pipe>;
}
