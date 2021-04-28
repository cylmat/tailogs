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

##########
# GLOBAL #
##########

use constant TAIL => "/usr/bin/tail";
use constant REGEX_CHARS => "[a-z ]";
use constant REGEX_NOCHARS => "[^a-z ]";

sub sed_args($$) {
  my $pattern = $_[0];
  my $replacement = $_[1];

  my $command = "echo '$pattern' | sed -E '$replacement'";
  my $replaced = `$command`;

  return $replaced;
}

sub pattern_to_items($) { # separated by space
    return split(/ /, "@_"); # alpha msg => [alpha, msg]
}

###################
# Define commands #
###################

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
    #"filename" => "/var/log/apt/history.log",
    "filename" => "/var/log/commerce.log",
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
  my $backslash = "\\\\";
  my $slashed_pattern = sed_args($pattern, "s/(".REGEX_NOCHARS.")/$backslash\\1/g");
  return $slashed_pattern; # alpha:msg => alpha\:msg
}

sub pattern_to_stars($) {
    my $slashed_pattern = "@_";
    my $star_pattern = sed_args($slashed_pattern, "s/([a-z]+)/(.*)/g");
    return $star_pattern; # alpha msg => (.*) (.*)
}

# actual: pattern alpha => 0 1
# new   : alpha pattern => \1 \0
# replace actual star "(.*) (.*)" by new with indexes "\1 \0"
sub process_patterns($$) {
    my $pattern = "$_[0]";
    my $new_pattern = "$_[1]";

    my $slashed_pattern = slash_nochars_pattern($pattern); # alpha\: beta
    my $star_pattern = pattern_to_stars($slashed_pattern); # (.*)\: (.*)
    my @actual_items = pattern_to_items($pattern); # [alpha, beta]

    my $new_pattern_by_items = "$new_pattern";
    for my $item_name (@actual_items) { # alpha beta gamma => 0 1 2
        my $index = "";
        $new_pattern_by_items = sed_args($new_pattern_by_items, "s/($item_name)/$index/g"); 
    }

    return $new_pattern_by_items;
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
  # config
  my %config = get_config();
  my @actual_patterns = ${config{'apache'}{'actual_patterns'}[0]};
  my @new_patterns = ${config{'apache'}{'new_patterns'}[0]};
  my $pattern = "${actual_patterns[0]}";
  my $new_pattern = "${new_patterns[0]}";

  # process
  my $new_one = process_patterns($pattern, $new_pattern);

  # run
  run_tail(%config);
}

main();
