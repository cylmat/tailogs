#!/usr/bin/env perl

# https://www.geeksforgeeks.org/perl-warnings-and-how-to-handle-them/

use strict;
use warnings;

# apt-get update && apt-get install -y locales locales-all
# echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale
# print "@{[ %hash ]}";
# foreach my $k (sort keys %config) { print "$k => $config{$k}\n"; }
# while ( ($k,$v) = each %hash ) { print "$k => $v\n"; }
# "${config{apache}{actual_patterns}[1]}";

##########
# GLOBAL #
##########

sub replace($$$) {
  my $pattern = $_[0];
  my $actual = $_[1];
  my $replace = '"'.$_[2].'"'; # used for /ee global evaluation

  $pattern =~ s/$actual/$replace/eeg;

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

sub dd($) {
    print $_[0]; exit;
}

sub debug($) {
    #print $_[0]."\n";
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
      "Commandline: <command> -y <msg>",
      "install: msg",
      "txtdate: date time"
    ],
    "new_patterns" => [
      "Commandline: 31<msg>0 <=> 32<command>0",
      "msgtwo local",
      "date date time&time"
    ]
  };

  return %config;
}

###########
# PROCESS #
###########

=begin
SLASH command\: msg
STAR (.*)\: (.*)
ITEMS command msg
ITEMSLIST command msg
NEW 31msg0 <=> 32command0
COLORNEW msg <=> command
NEW_BY_ITEMS \2 <=> \1
=cut

sub slash_nochars_pattern($) {
  my $pattern = "@_";
  my $slashed_pattern = replace($pattern, "([^a-z<> ])", '\\\\$1');
  debug("SLASH $slashed_pattern");
  return $slashed_pattern; # <alpha>: <msg> => <alpha>\: <msg>
}

sub pattern_to_stars($) {
  my $slashed_pattern = "@_";
  my $star_pattern = replace($slashed_pattern, "(<[a-z]+>)", "(.*)");
  debug("STAR $star_pattern");
  return $star_pattern; # <alpha> <msg> => (.*) (.*)
}

sub pattern_to_items($) {
  my $pattern = "@_";
  $pattern = replace($pattern, "\\s+", " "); # Trim multiple spaces
  my @items_list = ( $pattern =~ /(<[a-z]+>)/g );
  debug("ITEMSLIST @items_list");
  return @items_list;
}

sub number_to_color($) {
  # \033[0;31m
  # \033[0m
  my $pattern = "@_";
  my $colorized_pattern = replace($pattern, "0", '\\033[0m');
  $colorized_pattern = replace($colorized_pattern, "([1-9][1-9])", '\\033[0;$1m');
  return $colorized_pattern; # alpha msg => (.*) (.*)
}

# actual: pattern alpha => 0:1
# new   : alpha pattern => \1 \0
# replace actual star "(.*):(.*)" by new with indexes "\1 \0"
sub process_patterns($$) {
  my $pattern = "$_[0]";
  my $new_pattern = "$_[1]";

  #my $slashed_pattern = slash_nochars_pattern($pattern); # alpha\: beta
  my $star_pattern = pattern_to_stars($pattern); # (.*)\: (.*)
  my @actual_items = pattern_to_items($pattern); # [alpha, beta]
  
  # Colors
  debug("NEW $new_pattern");
  $new_pattern = number_to_color($new_pattern);
  debug("COLORNEW $new_pattern");

  my $new_pattern_by_items = "$new_pattern";
  for my $item_name (@actual_items) { # alpha beta gamma => 0 1 2
    my $index = get_index($item_name, \@actual_items)+1;
    $new_pattern_by_items = replace($new_pattern_by_items, "($item_name)", "\\\\$index"); 
  }
  debug("NEW_BY_ITEMS $new_pattern_by_items");
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
  $sed .= "'s/$params{'pattern'}/$params{'new_one'}/g' ";

  ###
  # Final command #
  push(@pipes, PIPE."$grep".PIPE."$sed");
  my $command = TAIL."@args"."@pipes";
  debug($command);

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
  #my $slashed_pattern = slash_nochars_pattern($pattern); # alpha\: beta
  my $star_pattern = pattern_to_stars($pattern); # (.*)\: (.*)

  my $new_one = process_patterns($pattern, $new_pattern);

  # Run
  my %params = (
    'filename' => $config{'apache'}{'filename'},
    'pattern' => $star_pattern,
    'new_one' => "$new_one"
  );
  run_tail(%params);
}

main();
