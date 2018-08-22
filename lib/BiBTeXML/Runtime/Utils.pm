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
  qw( &splitNameWords &getCase &splitNameParts ),    # TODO: Implement format.name$
  qw( &splitNames &numNames ),
  # TODO: Implement purify$
  # TODO: Implement substring$
  qw( &textLength ),
  # TODO: Implement text.prefix$
  # TODO: Implement width$
);

###
### Adding periods
###

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

###
### Changing case of a string
###

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

        # Gobble up everything until we are back at level 0
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
  my ($macro, $brace, $after) = ($accent =~ /^([^{]*)(\{|\s)(.*)$/m);
  if ($brace) {
    return $macro . $brace . ($spec eq 'u' ? uc $after : lc $after);

    # if we did not have a macro, return it untouched
  } else {
    return $accent;
  }

}

###
### Counting text length
###

# count's the text-length of a string
# does not count braces, and counts any accent (i.e. brace followed by a backslash) as 1. )
# implements text.length$
sub textLength {
  my ($string) = @_;

  my $level = 0;
  my $count = 0;
  my $character;

  # take the string and remove everything that is not of brace-level 0
  my @characters = split(//, $string);

  while ($character = shift(@characters)) {
    if ($level eq 0) {
      if ($character eq '{') {
        $level++;

        # pop the next character
        $character = shift(@characters);
        return $count unless defined($character);

        $count++;

        # if it has a backslash, eat every character
        # until we are balanced again.
        if ($character eq '\\') {
          while ($character = shift(@characters)) {
            $level++ if $character eq '{';
            $level-- if $character eq '}';
            last     if $level eq 0;
          }
        }
      } else {
        $count++;
      }
    } else {
      if ($character eq '{') {
        $level++;
      } elsif ($character eq '}') {
        $level--;
      } else {
        $count++;
      }
    }
  }

  return $count;
}

###
### Splitting into names
###

# splits a string into a list of names
# used for numNames and a couple of other utility functions
sub splitNames {
  my ($string) = @_;

  my $level  = 0;
  my $buffer = '';
  my @result = ('');
  my @cache;
  my $character;

  # accumalate entries inside of a buffer
  # and then split the buffer, once we reach a non-zero level
  my @characters = split(//, $string);
  while ($character = shift(@characters)) {
    if ($level eq 0) {
      $buffer .= $character;
      if ($character eq '{') {
        @cache = split(/\sand\s/, $buffer);
        $result[-1] .= shift(@cache);
        push(@result, @cache);

        # clear the buffer
        $buffer = '';
        $level++;
      }
    } else {
      $level++ if $character eq '{';
      $level-- if $character eq '}';
      # because we do not split
      # do not add to the buffer but into the last character
      $result[-1] .= $character;
    }
  }

  # split the buffer and put it into result
  if ($buffer) {
    @cache = split(/\sand\s/, $buffer);
    $result[-1] .= shift(@cache);
    push(@result, @cache);
  }

  # and return the results
  return @result;
}

# count the number of names inside of $string
# i.e. the number of times the word 'and' appears surrounded by spaces
# at brace level 0
# implements num.names$
sub numNames {
  return scalar(splitNames(@_));
}

###
### Formating names
###

# splits a single name into three lists
# one before all commas, one after the first one, one after the second one
sub splitNameWords {
  my ($string) = @_;

  my $level  = 0;
  my $buffer = '';
  my @result = ('');
  my @cache;
  my $character;

  my @characters = split(//, $string);
  while ($character = shift(@characters)) {
    if ($level eq 0) {
      $buffer .= $character;
      if ($character eq '{') {
        @cache = split(/[\s~-]+\K/, $buffer);    # use '\K' to split right *after* the match
        $result[-1] .= shift(@cache);
        push(@result, @cache);

        # clear the buffer
        $buffer = '';
        $level++;
      }
    } else {
      $level++ if $character eq '{';
      $level-- if $character eq '}';
      # because we do not split
      # do not add to the buffer but into the last character
      $result[-1] .= $character;
    }
  }

  # split the buffer and put it into result
  if ($buffer) {
    @cache = split(/[\s~-]+\K/, $buffer);    # use '\K' to split right *after* the match
    $result[-1] .= shift(@cache);
    push(@result, @cache);
  }

  my @precomma  = ();
  my @midcomma  = ();
  my @postcomma = ();
  my $pastcomma = 0;

  # iterate over our result array
  # and pop into the three appropriate lists
  while ($buffer = shift(@result)) {

    # we did not yet have a comma
    # so push everything into the first array
    # until we encounter a comma
    if ($pastcomma eq 0) {
      if ($buffer =~ /,\s+$/) {
        $buffer =~ s/,\s+$//;
        push(@precomma, $buffer) if length($buffer) > 0;
        $pastcomma++;
      } else {
        push(@precomma, $buffer);
      }
      # we had one comma
    } elsif ($pastcomma eq 1) {
      if ($buffer =~ /,\s+$/) {
        $buffer =~ s/,\s+$//;
        push(@midcomma, $buffer) if length($buffer) > 0;
        $pastcomma++;
      } else {
        push(@midcomma, $buffer);
      }
      # we had a third comma
    } else {
      push(@postcomma, $buffer);
    }
  }

  # and return the results
  return [@precomma], [@midcomma], [@postcomma];
}

# gets the 'case' of a single word of a name in a BiBTeX sense
# i.e. either 'u' or 'l'. If no alphabetic character exists, returns lower-case.
sub getCase {
  my ($string) = @_;
  my ($char);

  # if the string starts with { *and* it's not a TeX command its upper case
  return 'u' if ($string =~ /^\{[^\\]/);

  # if it is *not* a two letter accent
  # and we are of the form {\macro {arguments}}
  # then we are whatever that letter is
  unless ($string =~ /\{\\[a-z]{2}\}/) {
    ($char) = ($string =~ /\{\\[^\}\{\s]+(?:\{|\s)+([a-z])/im);
    return (($char =~ /[A-Z]/) ? 'u' : 'l') if $char;
  }

  # It is enough to find the first alphabetic character
  # because we can now assume we are a TeX Character
  my ($char) = ($string =~ /([a-z])/i);
  return 'l' unless $char;
  return ($char =~ /[A-Z]/) ? 'u' : 'l';
}

# splits a single name into parts (first, von, jr, last)
# uses the BiBTeX name location
sub splitNameParts {
  my ($string) = @_;

  # split the name into words
  my ($pre, $mid, $post) = splitNameWords($string);
  my @prec  = @$pre;
  my @midc  = @$mid;
  my @postc = @$post;

  # prepare all the parts
  my @first = ();
  my @von   = ();
  my @jr    = ();
  my @last  = ();

  # start by splitting off everything except for 'von Last'
  # which we will both store in @von for now (and split below)
  my $word;
  my $gotlower = 0;

  # Style (i): "First von Last"
  if (scalar(@midc) eq 0 && scalar(@postc) eq 0) {
    # if we only have upper case letters, they are all last names
    while ($word = shift(@prec)) {
      # if we encounter a lower-case, everything before that is first name
      # and everything including and after it is "von Last"
      if (getCase($word) eq 'l') {
        $gotlower = 1;
        @first    = @von;
        @von      = ($word, @prec);
        last;
      }
      push(@von, $word);
    }

    # if we did not get any lower-case words
    # then the last word is the last name
    # and the rest the first name.
    unless ($gotlower) {
      @first = @von;
      @von   = pop(@first);
    }

    # we did not get any words in the 'von Last' part
    # so that the last of the first name
    if (scalar(@von) eq 0) {
      push(@von, pop(@first));
    }

    # Style (ii): "von Last, First"
  } elsif (scalar(@postc) eq 0) {
    @von   = @prec;
    @last  = @prec;
    @first = @midc;

    # Style (iii): "von Last, Jr, First"
  } else {
    @von   = @prec;
    @jr    = @midc;
    @first = @postc;
  }

  my $haslast = 0;

  # we now split the "von Last" part
  while ($word = pop(@von)) {
    # find the last small word and push it into last
    if ($haslast && getCase($word) eq 'l') {
      push(@von, $word);
      last;

      # push all the big words from 'von' into 'last'
    } else {
      unshift(@last, $word);
      $haslast = 1;
    }
  }

  # If the Last part follows the '-' character
  # then that part belongs to the last part too
  if (scalar(@von) eq 0 && scalar(@last) > 0) {
    while (scalar(@first) && substr($first[-1], -1, 1) eq '-') {
      $last[0] = pop(@first) . $last[0];
    }
  }

  return [@first], [@von], [@jr], [@last];
}
