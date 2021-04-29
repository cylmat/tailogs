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

use constant REGEX_CHARS => "[a-z ]";
use constant REGEX_NOCHARS => "[^a-z ]";

sub replace($$$) {
  my $pattern = $_[0];
  my $actual = $_[1];
  my $replace = '"'.$_[2].'"'; # used for /ee evaluation

  $pattern =~ s/$actual/$replace/ee;

  return $pattern;
}

sub split_spaces($) { # separated by space
  return split(/ /, "@_"); # alpha msg => [alpha, msg]
}

sub get_index($@) { # search_value, @array
  my $value = $_[0];
  my @array = @{$_[1]};

  my $i = 0; 
  my $index = -1;
  foreach (@array) {
      if ("$array[$i]" eq $value) { 
        $index = $i; 
      }
      $i++;
  }

  return $index; # beta [alpha, beta] => 1
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
    "filename" => "/var/log/apt/history.log",
    #"filename" => "/var/log/commerce.log",
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
  my $slashed_pattern = replace($pattern, "(".REGEX_NOCHARS.")", '\\\\$1');
  return $slashed_pattern; # alpha:msg => alpha\:msg
}

sub pattern_to_stars($) {
  my $slashed_pattern = "@_";
  my $star_pattern = replace($slashed_pattern, "([a-z]+)", "(.*)");
  return $star_pattern; # alpha msg => (.*) (.*)
}

sub pattern_to_items($) {
  my $pattern = "@_";
  $pattern = replace($pattern, "[ ]+", " "); # trim multiple spaces
  my $only_items = replace($pattern, "[^a-z ]",'');
  my @items_list = split_spaces($only_items);
  return @items_list;
}

# actual: pattern alpha => 0:1
# new   : alpha pattern => \1 \0
# replace actual star "(.*):(.*)" by new with indexes "\1 \0"
sub process_patterns($$) {
  my $pattern = "$_[0]";
  my $new_pattern = "$_[1]";

  my $slashed_pattern = slash_nochars_pattern($pattern); # alpha\: beta
  my $star_pattern = pattern_to_stars($slashed_pattern); # (.*)\: (.*)
  my @actual_items = pattern_to_items($pattern); # [alpha, beta]

  my $new_pattern_by_items = "$new_pattern";
  for my $item_name (@actual_items) { # alpha beta gamma => 0 1 2
    my $index = get_index($item_name, \@actual_items);
    $new_pattern_by_items = replace($new_pattern_by_items, "($item_name)", "\\\\$index"); 
  }

  return $new_pattern_by_items;
}

########
# MAIN #
########

sub run_tail(%) {
  my %params = @_;
  #print "${config{apache}{actual_patterns}[1]}";

  use constant TAIL => "/usr/bin/tail ";
  use constant PIPE => " | ";
  
  my @args = ();
  my @pipes = ();

  ###
  # Tail args #
  push(@args, "-n 3 ");
  push(@args, $params{'filename'});

  ###
  # Pipes

  # Grep
  my $grep = "grep ";
  $grep .= "'\.' ";

  # Sed
  my $sed = "sed -E ";
  $sed .= "'s/(.*)/\\1/g' ";

  ###
  # Final command #
  push(@pipes, PIPE."$grep".PIPE."$sed");
  my $command = TAIL."@args"."@pipes";
  #print $command; exit; #DEBUG

  # RUN TAIL #
  open my $tail_pipe, "-|", $command or die "Error - Could not start tail on $params{'filename'}: $!";
  print while <$tail_pipe>;
}

sub main {
  # Config
  my %config = get_config();
  my @actual_patterns = ${config{'apache'}{'actual_patterns'}[0]};
  my @new_patterns = ${config{'apache'}{'new_patterns'}[0]};

  # @TODO foreach
  my $pattern = "${actual_patterns[0]}";
  my $new_pattern = "${new_patterns[0]}";

  # Process
  my $new_one = process_patterns($pattern, $new_pattern);

  # Run
  my %params = (
    'filename' => $config{'apache'}{'filename'},
    'pattern' => $pattern,
    'new_one' => $new_one
  );
  run_tail(%params);
}

main();
