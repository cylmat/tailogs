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
  # "${config{apache}{filename}}";
  # "${config{apache}{actual_patterns}[1]}";
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
use constant REGEX_CHARS => "[a-z ]";
use constant REGEX_NOCHARS => "[^a-z ]";

# for my $family ( sort keys %HoA ) {
#   print "$family: "; 
#   while (my ($index, $elem) = each @{$HoA{$family}}) {
#     print "$index $elem ";
#   }
#   print "\n"; 
# }

sub get_config {
  my %config = ();
  
  @config{'apache'} = {
    "filename" => "/var/log/apt/history.log",
    "actual_patterns" => [
      "command: msg",
      "install: msg2",
      "txtdate: date time"
    ],
    "new_patterns" => [
      "msg-command",
      "msg2 local",
      "date date time&time"
    ]
  };

  return %config;
}

###########
# PROCESS #
###########
sub slash_nochars_pattern($) {
  my $pattern = "@_";
  
  my $command = "echo '$pattern' | sed -E 's/(".REGEX_NOCHARS.")/\\\\\\1/g'";
  my $slashed_pattern = `$command`;

  return $slashed_pattern;
}

########
# MAIN #
########

sub run_tail(%) {
  my %config = @_;
  #print "${config{apache}{actual_patterns}[1]}";

  # ARGS #
  my @args = ("-n 3");
  push(@args, $config{'apache'}{'filename'});

  my $tail_args = TAIL . " @args";
  #print $tail_args; exit; #DEBUG

  # RUN TAIL #
  open my $tail_pipe, "-|", $tail_args or die "Error - Could not start tail on $config{'filename'}: $!";
  print while <$tail_pipe>;
}

sub main {
  my %config = get_config();
  my @patterns = ${config{'apache'}{'actual_patterns'}[0]};
  my $pattern = "${patterns[0]}";

  # process
  my $slashed_pattern = slash_nochars_pattern($pattern);

  # run
  run_tail(%config);
}

main();
