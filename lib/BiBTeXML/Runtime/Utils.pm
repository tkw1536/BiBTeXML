# /=====================================================================\ #
# |  BiBTeXML::Runtime::Utils                                           | #
# | Runtime utility functions                                           | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Utils;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = (
  qw( &addPeriod ),
  qw( &changeAccent &changeCase ),
  # TODO: Implement format.name$
  qw( &numNames ),
);

# takes a string and adds a ‘.’ to it
# if the last non-'}' character isn’t a ‘.’, ‘?’, or ‘!’, and pushes this resulting string.
# implements the add.period$ built-in
sub addPeriod {
  my ($string) = @_;

  # find the last character that is not a '}'
  my ($match) = ($string =~ m/(.)(?:\})*$/);

  # and add a '.' if it's not punctiation
  unless ($match && ($match eq '!' or $match eq '.' or $match eq '?')) {
    return $string . '.';
  } else {
    return $string;
  }
}

# changes the case of $string according to spec
# - if $spec is 't', then upper-case the first character and lower-case the rest
# - if $spec is 'u' then upper-case everything
# - if $spec is 'l' then lower-case everything
# handles accents, and ignores everything inside {s.
# implements the change.case$ built-in
sub changeCase {
  my ($string, $spec) = @_;
  $spec = lc($spec);

  # split the string into characters
  my @characters = split(//, $string);
  my ($level, $firstpassed) = (0, 0);
  my $result = '';
  my $buffer = '';

  # Iterate over the characters
  my ($character, $theSpec);
  while ($character = shift(@characters)) {
    if ($level eq 0) {
      if ($character eq '{') {
        # add the backslash for sure
        $result .= $character;
        $level++;

        # read the next character
        $character = shift(@characters);
        last unless defined($character);

        # if we do not have a backslash
        # then put the character back and continue at level 1
        unless ($character eq '\\') {
          unshift(@characters, $character);
          $firstpassed = 1;
          next;
        }
        $result .= $character;

        # buffer everything until we are at level 0 again
        $buffer  = '';
        $theSpec = $spec;
        $theSpec = $firstpassed ? 'l' : 'u' if $spec eq 't';

        # TODO: Gobble everything until we have level 0 again
        while (1) {
          $character = shift(@characters);

          # if we run out, before the bracket ends
          # we change the partial buffer
          # and then finish
          unless (defined($character)) {
            $result .= changeAccent($buffer, $theSpec);
            return $result;
          }

          # keep reading {s
          if ($character eq '{') {
            $level++;
          } elsif ($character eq '}') {
            $level--;
            last if $level eq 0;
          }
          $buffer .= $character;
        }
        $result .= changeAccent($buffer, $theSpec);
        $result .= '}';
      } else {
        if ($spec eq 'l') {
          $result .= lc $character;
        } elsif ($spec eq 'u') {
          $result .= uc $character;
        } else {
          $result .= $firstpassed ? lc $character : uc $character;
        }
      }

      # at positive levels, do not touch any characters
    } else {
      $result .= $character;
      $level++ if $character eq '{';
      $level-- if $character eq '}';
    }
    $firstpassed = 1;
  }

  return $result;
}

# changes an accent (in the BiBTeX sense) either to upper or lower case
# assumes that outer '{', '\' and '}' have already been removed
sub changeAccent {
  my ($accent, $spec) = @_;

  # if we have a length of 2, the second character needs to be alphabetical
  # the first character needs to be either alphabetical or one of: ', `, ^, ", ~, =, .
  if (length($accent) eq 2) {
    return $accent unless $accent =~ /^[a-z'`\^"~=\.][a-z]/i;
    return $spec eq 'u' ? uc $accent : lc $accent;
  }

  # if we have a brace, leave everything before untouched
  # and change the case of everything after
  my ($macro, $brace, $after) = ($accent =~ /^([^{]*)(\{)(.*)$/m);
  if ($brace) {
    return $macro . $brace . ($spec eq 'u' ? uc $after : lc $after);

    # if we did not have a macro, return it untouched
  } else {
    return $accent;
  }

}

# count the number of names inside of $string
# i.e. the number of times the word 'and' appears surrounded by spaces
# at brace level 0
# implements num.names$
sub numNames {
  my ($string) = @_;

  my $level  = 0;
  my $result = '';
  my $character;

  # take the string and remove everything that is not of brace-level 0
  my @characters = split(//, $string);
  while ($character = shift(@characters)) {
    if ($level eq 0) {
      if ($character eq '{') {
        $level++;
      } else {
        $result .= $character;
      }
    } else {
      $level++ if $character eq '{';
      $level-- if $character eq '}';
    }
  }

  # and count the number of times we have an 'and' surrounded by spaces
  return (() = $result =~ /\sand\s/ig) + 1;
}
