#!/usr/bin/perl -w

# MIT License

# Copyright (c) 2021 Cylmat

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use strict; use warnings;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt pass_through);

# apt-get update && apt-get install -y locales locales-all

##########
# GLOBAL #
##########

sub get_options() { # tail -cfFnqsvz
    my %opts;
    GetOptions( \%opts, 
        'logfile|g=s',
        'help|h'
    );
    return %opts;
}

# sub hasopt($) {
#     if (defined($opts{$_[0]})) { return 1; } else { return 0; }
# }

sub print_usage {
    print "Usage: $0 [OPTION]...\n";
}

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

###################
# Define commands #
###################

sub get_config {
  my %config = ();
  
  @config{'apache'} = {
    "filename" => "/var/log/apt/history.log",
    "actual_patterns" => [
      "Commandline: <command> -y <msg>",
      "Install: <msg>:<type>",
      "<txtdate>: <date> <time>",
      "<ubuntu> -> <rewrited>"
    ],
    "new_patterns" => [
      "Commandline: 31<msg>0 <=> 32<command>0",
      "<type> -> installed is 32<msg>0",
      "<date> <date> <time> ERT <time>",
      "<ubuntu> *** <rewrited>"
    ]
  };

  return %config;
}

###########
# PROCESS #
###########

sub slash_nochars_pattern($) { # $pattern
  my $slashed_pattern = replace("@_", "([^a-z<> ])", '\\\\$1');
  return $slashed_pattern; # <alpha>: <msg> => <alpha>\: <msg>
}

sub pattern_to_stars($) { # $slashed_pattern
  my $star_pattern = replace("@_", "(<[a-z]+>)", "(.*)");
  return $star_pattern; # <alpha> <msg> => (.*) (.*)
}

sub pattern_to_items($) { # $pattern
  my $pattern = replace("@_", "\\s+", " "); # Trim multiple spaces
  my @items_list = ( $pattern =~ /(<[a-z]+>)/g );
  return @items_list;
}

sub number_to_color($) { # $pattern
  # \033[0;31m
  # \033[0m
  my $colorized_pattern = replace("@_", "0", '\\033[0m');
  $colorized_pattern = replace($colorized_pattern, "([1-9][1-9])", '\\033[0;$1m');
  return $colorized_pattern; # alpha msg => (.*) (.*)
}

# actual: pattern alpha => 0:1
# new   : alpha pattern => \1 \0
# replace actual star "(.*):(.*)" by new with indexes "\1 \0"
sub process_patterns($$) {
  # my $pattern = "$_[0]";
  # my $new_pattern = "$_[1]";

  #my $slashed_pattern = slash_nochars_pattern($pattern); # alpha\: beta
  my $star_pattern = pattern_to_stars("$_[0]"); # (.*)\: (.*)
  my @actual_items = pattern_to_items("$_[0]"); # [alpha, beta]
  
  # Colors
  my $new_pattern_by_items = number_to_color("$_[1]"); # new_pattern = "$_[1]";
  for my $item_name (@actual_items) { # alpha beta gamma => 0 1 2
    my $index = get_index($item_name, \@actual_items)+1;
    $new_pattern_by_items = replace($new_pattern_by_items, "($item_name)", "\\\\$index"); 
  }

  return $new_pattern_by_items;
}

########
# MAIN #
########

sub run_tail(%) {
  my %params = @_;
  my $count = $params{'count'};
  # print "${config{apache}{actual_patterns}[1]}";

  use constant TAIL => "/usr/bin/tail ";
  use constant PIPE => " | ";
  
  my @args = @ARGV;
  my @pipes = ();

  ###
  # Tail args #
  push(@args, $params{'filename'});

  ###
  # Pipes

  # Grep
  my $grep = "grep ";
  $grep .= "'\.' ";

  # Sed
  my $sed = "";
  use constant TOKEN => 'TAILOGSTOKEN1'; # Avoid duplicate line replacement

  for (my $i = 0; $i <= $count; $i++) {
    my $a = 'actual'.$i;
    my $n = 'new'.$i;
    if (!defined($params{$a}) || !defined($params{$n})) {
      print "Patterns not founds.\n" || exit(2);
    }

    my $replace = TOKEN."$params{$n}";
    my $sed_not_begin_with = "/^".TOKEN."/!s";
    $sed .= ($i>0 ? PIPE : '') . "sed -E '$sed_not_begin_with/$params{$a}/$replace/g' ";
  }
  # Remove Sed begin line's tokens
  $sed .= PIPE . "sed -E 's/".TOKEN."//g' ";

  ###
  # Final command #
  push(@pipes, PIPE."$grep".PIPE."$sed");
  my $command = TAIL."@args"."@pipes";
  #print $command; exit;

  # RUN TAIL #
  open my $tail_pipe, "-|", $command or die "Error - Could not start tail on $params{'filename'}: $!";
  print while <$tail_pipe>;
}

sub main {
  # Options
  get_options();

  # Config
  my %config = get_config();
  my @actual_patterns = ();
  my @new_patterns = ();
  my $count = undef;

  # Process
  my %params = ();

  for (my $i=0; $i<100; $i++) {
    my $actual = ${config{'apache'}{'actual_patterns'}[$i]};
    my $new = ${config{'apache'}{'new_patterns'}[$i]};
    if (!defined($actual) || !defined($new)) {
        last;
    }
    
    $params{'actual'.$i} = pattern_to_stars($actual); # (.*)\: (.*)
    $params{'new'.$i} = process_patterns($actual, $new);

    $count = $i;
  }

  if (!defined($count)) {
      print "Impossible to read patterns." || exit(3);
  }

  # Process
  $params{'filename'} = $config{'apache'}{'filename'};
  $params{'count'} = $count;

  # Run
  run_tail(%params);
}

main();
