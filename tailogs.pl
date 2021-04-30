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
    print $_[0]."\n"; exit;
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
      "Install: <msg>:<type>",
      "<txtdate>: <date> <time>"
    ],
    "new_patterns" => [
      "Commandline: 31<msg>0 <=> 32<command>0",
      "<type> -> installed is 32<msg>0",
      "<date> <date> <time> ERT <time>"
    ]
  };

  return %config;
}

###########
# PROCESS #
###########

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
  my $count = $params{'count'};
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
  my $sed = "";
  for (my $i = 0; $i <= $count; $i++) {
    my $a = 'actual'.$i;
    my $n = 'new'.$i;
    if (!defined($params{$a}) || !defined($params{$n})) {
      print "Patterns not founds.\n" || exit(2);
    }

    $sed .= ($i>0 ? PIPE : '') . "sed -E 's/$params{$a}/$params{$n}/g' ";
  }

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
  my @actual_patterns = ();
  my @new_patterns = ();
  my $count = undef;

  for (my $i=0; $i<100; $i++) {
    my $actual = ${config{'apache'}{'actual_patterns'}[$i]};
    my $new = ${config{'apache'}{'new_patterns'}[$i]};
    if (!defined($actual) || !defined($new)) {
        last;
    }
    push(@actual_patterns, $actual);
    push(@new_patterns, $new);
    $count = $i;
  }

  if (!defined($count)) {
      print "Impossible to read patterns." || exit(3);
  }

  # Process
  my %params = (
    'filename' => $config{'apache'}{'filename'},
    'count' => $count
  );

  for (my $i = 0; $i <= $count; $i++) {
    if (!defined($actual_patterns[$i]) || !defined($new_patterns[$i])) {
      print "Patterns n°$i not founds.\n" || exit(4);
    }

    my $star_pattern = pattern_to_stars($actual_patterns[$i]); # (.*)\: (.*)
    my $new_one = process_patterns($actual_patterns[$i], $new_patterns[$i]);

    $params{'actual'.$i} = $star_pattern;
    $params{'new'.$i} = $new_one;
  }

  # Run
  run_tail(%params);
}

main();
