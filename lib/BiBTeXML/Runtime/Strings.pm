# /=====================================================================\ #
# |  BiBTeXML::Runtime::Strings                                         | #
# | Runtime string functions                                            | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Strings;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(
  &addPeriod
  &splitLetters &parseAccent
  &changeCase &getCase
  &textSubstring
  &textLength
  &textPrefix
  &textWidth
  &textPurify
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
### Splitting text into characters
###

# splits text into an array of semantic characters (i.e. including accents).
# includes a second array, stating the level of each characters
sub splitLetters {
  my ($string) = @_;

  # split the string into characters
  my @characters = split(//, $string);

  # current letter and brace level
  my ($buffer, $hadLetter, $level) = ('', 0, 0);
  my @letters = ('');
  my @levels  = (0);

  my $char;
  while (defined($char = shift(@characters))) {
    if ($char eq '{') {
      $level++;
      if ($level eq 1) {

        # if the next character is a \, then we need to go into accent handling
        # and read up until the end of the accent.
        $char = shift(@characters);
        if (defined($char) && $char eq '\\') {
          $buffer = '{\\';

          # read characters until we are balanced again
          while (defined($char = shift(@characters))) {
            $buffer .= $char;
            $level++ if $char eq '{';
            $level-- if $char eq '}';
            last     if $level eq 0;
          }

          # push the collected accent and go back into normal mode
          shift(@letters) unless $hadLetter;
          shift(@levels)  unless $hadLetter;
          push(@letters, $buffer);
          push(@levels,  0);
          $hadLetter = 1;
          next;
        } else {
          unshift(@characters, $char) if defined($char);
          $char = '{';
        }
      }

      # for nested opening braces
      # add to the previous one
      if ($hadLetter && substr($letters[-1], -1) eq '{') {
        $letters[-1] .= '{';
        $levels[-1] = $level;

        # else create a new opening element
      } else {
        shift(@letters) unless $hadLetter;
        shift(@levels)  unless $hadLetter;
        push(@letters, $char);
        push(@levels,  $level);
        $hadLetter = 1;
      }

      # if we have a closing brace, just add it to the previous one
      # and decrease the level (but never go negative)
    } elsif ($char eq '}') {
      $letters[-1] .= '}';
      $hadLetter = 1;
      $level-- unless $level eq 0;
    } else {
      # if we had an opening brace, append to it
      if ($hadLetter && substr($letters[-1], -1) eq '{') {
        $letters[-1] .= $char;

        # else push a normal character
      } else {
        shift(@letters) unless $hadLetter;
        shift(@levels)  unless $hadLetter;
        push(@letters, $char);
        push(@levels,  $level);
        $hadLetter = 1;
      }
    }
  }

  my @theletters = ();
  my @thelevels  = ();

  my $letter;
  while (defined($letter = shift(@letters))) {
    $level = shift(@levels);

    # if we have a letter that is only braces
    if ($letter =~ /^[\{\}]*$/) {
      # then try and prepend to the next letter
      if (scalar(@letters) ne 0) {
        $letters[0] = $letter . $letters[0];
        # or the last letter in the output
      } elsif (scalar(@theletters) ne 0) {
        $theletters[-1] .= $letter;
        # if we don't have anything, then only push the letter
        # so that scalar(@levels) still indiciates the string length
      } else {
        push(@theletters, $letter);
      }
    } else {
      push(@theletters, $letter);
      push(@thelevels,  $level);
    }

  }
  return [@theletters], [@thelevels];
}

# checks if a balanced string is an accent,
# and if so returns (1, $outerPrefix, $innerPrefix, $content, $innerSuffix, $outerSuffix, $command, $commandArgs)
# - $outerPrefix is a string prefixing the accent, but not belonging to it at all
# - $innerPrefix is the part of the accent that is not-case sensitive
# - $content is the case-sensitive part of the accent
# - $innerSuffix is a string following the accent, and belonging to it
# - $outerSuffix is a string following the accent, but not belonging to it at all
# - $command is the command used to built the accent (if any)
# - $commandArgs is the arguments of the command (if any)
# the following inequality holds:
# $string eq $outerPrefix . $innerPrefix . $content . $innerSuffix . $outerSuffix
# if not returns (0, '', '', $string, '', '', undef, undef)
sub parseAccent {
  my ($string) = @_;

  # an accent has to start with {\\
  if ($string =~ /^[\{\}]*\{\\/) {
    # strip off leading {}s
    my ($outerPrefix, $accent) = ($string =~ /^([\{\}]*)\{\\(.*)/);
    my ($innerPrefix, $innerSuffix) = ('{\\', '');

    # read content as the balanced substring
    my ($char, $content, $outerSuffix) = ('', '', '');
    my ($level, $passedContent) = (1, 0);
    my @characters = split(//, $accent);
    foreach $char (@characters) {
      unless ($passedContent) {
        $content .= $char;
        $level++ if $char eq '{';
        $level-- if $char eq '}';
        $passedContent = 1 if $level eq 0;
      } else {
        $outerSuffix .= $char;
      }
    }

    # if we are at level 0, we had a closing brace
    # remove that from CONTENT
    if ($level eq 0) {
      $content = substr($content, 0, -1);
      $innerSuffix = '}';
    }

    # accent = trim both ends of $conent
    $accent = $content;
    $accent =~ s/^\s+|\s+$//g;

    my ($prefix, $suffix, $command, $commandArgs);

    # if we have one of the special accents
    if (
      $accent eq 'OE' or
      $accent eq 'ae' or
      $accent eq 'AE' or
      $accent eq 'aa' or
      $accent eq 'AA' or
      $accent eq 'o'  or
      $accent eq 'O'  or
      $accent eq 'l'  or
      $accent eq 'L'  or
      $accent eq 'ss'
    ) {
      # hey, we know this command
      $command     = $accent;
      $commandArgs = '';

      # we need to keep track fo the prefix and suffix of it
      ($prefix) = ($accent =~ m/^(\s+)/);
      $innerPrefix .= $prefix if defined($prefix);
      ($suffix) = ($accent =~ m/(\s+)$/);
      $innerSuffix = $suffix . $innerSuffix if defined($suffix);

      # else take either
    } else {

      # the first character after a space or opening bracket
      ($prefix, $accent) = ($content =~ m/^([^\s\{]*)([\s\{].*)$/);
      if (defined($accent)) {
        $innerPrefix .= $prefix if defined($prefix);
        $command = $prefix if defined($prefix);

        $commandArgs = $accent;
        $commandArgs =~ s/^\s+|\s+$//g;
        $commandArgs =~ s/\{(.*)\}/$1/g;

        # everything if we do not have any spaces or brackets
      } else {
        $accent = $content;

        # if we have some non-alphabetical characters then those are the command
        ($command, $commandArgs) = ($accent =~ m/^([^a-z]+)([a-z]+)$/i);
        unless (defined($command)) {
          $command     = $accent;
          $commandArgs = '';
        }
      }

      # remove prefixed spaces (if any)
      ($prefix) = ($accent =~ m/^(\s+)/);
      $accent =~ s/^(\s+)//;
      $innerPrefix .= $prefix if defined($prefix);

      # remove suffixed spaces (if any)
      ($suffix) = ($accent =~ m/(\s+)$/);
      $accent =~ s/(\s+)$//;
      $innerSuffix = $suffix . $innerSuffix if defined($suffix);

      # remove the surrounding braces
      if (substr($accent, 0, 1) eq '{' && substr($accent, -1, 1) eq '}') {
        $innerPrefix .= '{';
        $innerSuffix .= '}';
        $accent = substr($accent, 1, -1);
      }
    }
    return 1, $outerPrefix, $innerPrefix, $accent, $innerSuffix, $outerSuffix, $command, $commandArgs;

    # this isn't an accent -- what did you pass?
  } else {
    return 0, '', '', $string, '', '', undef, undef;
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

  # normalize the specification and split off letters
  $spec = lc $spec;
  my ($letters, $levels) = splitLetters($string);

  # things we will use
  my $index = 1;
  my ($result, $letter, $level);
  my ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $command);

  # iterate over each level
  foreach $letter (@$letters) {
    $level = shift(@$levels);

    # change case if we are on level 0
    if ($level eq 0) {
      ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $command) = parseAccent($letter);

      # upper case (or first letter of t)
      if ($spec eq 'u' or ($spec eq 't' && $index eq 1)) {
        # special case: \ss is the only accent to be changed into a non-accent
        if ($isAccent && defined($command) && $command eq 'ss') {
          $result .= $oPrefix . 'SS' . $oSuffix;
        } else {
          $result .= $oPrefix . $iPrefix . (uc $accent) . $iSuffix . $oSuffix;
        }
        # lower case (or non-first letter of t)
      } else {
        $result .= $oPrefix . $iPrefix . (lc $accent) . $iSuffix . $oSuffix;
      }

      # do not touch anything
      # of positive level
    } else {
      $result .= $letter;
    }
    $index++;
  }

  return $result;
}

# gets the 'case' of a single letter of a name in a BiBTeX sense
# i.e. either 'u' or 'l'. If no alphabetic character exists, returns lower-case.
sub getCase {
  my ($string) = @_;

  # parse the accent
  my ($isAccent, $oPrefix, $iPrefix, $search, $iSuffix, $oSuffix) = parseAccent($string);

  # if it is not an accent, but starts with '{', then it is upper-case
  return 'u' if substr($string, 0, 1) eq '{' && !$isAccent;

  # else find the first alphabetic character in it
  $search .= $iSuffix . $oSuffix;
  ($search) = ($search =~ /([a-z])/i);
  return 'l' unless $search;
  return ($search =~ /[A-Z]/) ? 'u' : 'l';
}

###
### Text Length, Width and substring
###

# counts the text-length of a string
# implements text.length$
sub textLength {
  my ($string) = @_;

  my ($letters, $levels) = splitLetters($string);
  return scalar(@$levels);
}

# returns the prefix of length $length of a string
# implements text.prefix$
sub textPrefix {
  my ($string,  $length) = @_;
  my ($letters, $levels) = splitLetters($string);

  # read a prefix of the string
  my $index  = 0;
  my $result = '';
  my $letter;
  while (defined($letter = shift(@$letters))) {
    $result .= $letter;
    $index++;
    last if $index eq $length;
  }

  # balance brackets magically
  my $level = () = ($result =~ /{/g);
  $level -= () = ($result =~ /}/g);
  if ($level >= 0) {
    $result .= ('}' x $level);
  }

  return $result;
}

# compute the width of text in hundredths of a point, as specified by the June 1987 version of the cmr10 font
# implements width$
sub textWidth {
  my ($string) = @_;
  my ($letters, $levels) = splitLetters($string);

  # iterate over each of the letters
  my $width = 0;
  my @characters;
  my ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $command, $commandArgs, $letter, $level);
  foreach $letter (@$letters) {
    $level = shift(@$levels);

    # on level 0, check for accents
    if (defined($level) && $level eq 0) {

      # parse the accent
      ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $command, $commandArgs) = parseAccent($letter);
      # if we have a command in $accent, add the width of that 'character'
      if (defined($command)) {
        $width += commandWidth($command, $commandArgs);

        # and add the length of the outer prefix and suffix
        @characters = split(//, $oPrefix);
        $width += characterWidth($_) foreach (@characters);

        @characters = split(//, $oSuffix);
        $width += characterWidth($_) foreach (@characters);

        # if it's not a command
        # just count the length of the content, outer prefix and suffix
      } elsif ($isAccent) {
        @characters = split(//, $accent);
        $width += characterWidth($_) foreach (@characters);

        @characters = split(//, $oPrefix);
        $width += characterWidth($_) foreach (@characters);

        @characters = split(//, $oSuffix);
        $width += characterWidth($_) foreach (@characters);

        # if it is not an accent, count each letter individually
      } else {
        @characters = split(//, $letter);
        $width += characterWidth($_) foreach (@characters);
      }

      # on level 1+, we need to add up the width of each character individually
    } else {
      @characters = split(//, $letter);
      $width += characterWidth($_) foreach (@characters);
    }
  }
  return $width;
}

# table adpoted from
# https://metacpan.org/source/NODINE/Text-BibTeX-BibStyle-0.03/lib/Text/BibTeX/BibStyle.pm
# contains widths of accents and basic characters
our %WIDTHS =
  (0040 => 278, 0041 => 278, 0042 => 500, 0043 => 833, 0044 => 500,
  0045 => 833, 0046 => 778, 0047 => 278, 0050 => 389, 0051 => 389,
  0052 => 500, 0053 => 778, 0054 => 278, 0055 => 333, 0056 => 278,
  0057 => 500, 0060 => 500, 0061 => 500, 0062 => 500, 0063 => 500,
  0064 => 500, 0065 => 500, 0066 => 500, 0067 => 500, 0070 => 500,
  0071 => 500, 0072 => 278, 0073 => 278, 0074 => 278, 0075 => 778,
  0076 => 472, 0077 => 472, 0100 => 778,

  # A-Z
  0101 => 750, 0102 => 708, 0103 => 722,  0104 => 764, 0105 => 681,
  0106 => 653, 0107 => 785, 0110 => 750,  0111 => 361, 0112 => 514,
  0113 => 778, 0114 => 625, 0115 => 917,  0116 => 750, 0117 => 778,
  0120 => 681, 0121 => 778, 0122 => 736,  0123 => 556, 0124 => 722,
  0125 => 750, 0126 => 750, 0127 => 1028, 0130 => 750, 0131 => 750,
  0132 => 611,

  0133 => 278, 0134 => 500, 0135 => 278, 0136 => 500, 0137 => 278,
  0140 => 278,

  # a-z
  0141 => 500, 0142 => 556, 0143 => 444,  0144 => 556, 0145 => 444,
  0146 => 306, 0147 => 500, 0150 => 556,  0151 => 278, 0152 => 306,
  0153 => 528, 0154 => 278, 0155 => 833,  0156 => 556, 0157 => 500,
  0160 => 556, 0161 => 528, 0162 => 392,  0163 => 394, 0164 => 389,
  0165 => 556, 0166 => 528, 0167 => 722,  0170 => 528, 0171 => 528,
  0172 => 444, 0173 => 500, 0174 => 1000, 0175 => 500, 0176 => 500,

  aa => 500, AA => 750, o  => 500, O  => 778, l  => 278,  L    => 625,
  ss => 500, ae => 722, oe => 778, AE => 903, OE => 1014, '?`' => 472,
  '!`' => 278,
  );

# computes the width of a single character
sub characterWidth {
  my ($char) = @_;

  my $width = $WIDTHS{ ord $char };
  return $width if defined($width);
  return 500;
}

# computes the width of a command call
sub commandWidth {
  my ($command, $args) = @_;

  # if it is a known command, return the width of that command
  my $width = $WIDTHS{$command};
  return $width if defined($width);

  # else return the width of each character
  # and add them up
  $width = 0;
  my @characters = split(//, $args);
  $width += characterWidth($_) foreach (@characters);
  return $width;
}

# returns the prefix of length $length of a string
# implements substring$
sub textSubstring {
  my ($string, $start, $length) = @_;
  return substr($string, $start > 0 ? $start - 1 : $start - 2, $length);
}

###
### Purification
###

# purifies text to be used for sorting
# implements purify$
sub textPurify {
  my ($string) = @_;
  my ($letters, $levels) = splitLetters($string);

  # iterate over each of the letters
  my $purified = '';
  my @characters;
  my ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $command, $commandArgs, $letter, $level);
  foreach $letter (@$letters) {
    $level = shift(@$levels);

    # on level 0, check for accents
    if (defined($level) && $level eq 0) {

      # parse the accent
      ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $command, $commandArgs) = parseAccent($letter);

      # if we have one of the known command, transfer those into the appropriate ones
      if (defined($command) && (
          $command eq 'OE' or
          $command eq 'ae' or
          $command eq 'AE' or
          $command eq 'aa' or
          $command eq 'AA' or
          $command eq 'o'  or
          $command eq 'O'  or
          $command eq 'l'  or
          $command eq 'L'  or
          $command eq 'ss'
      )) {
        $purified .= $command;

        # if we had a command, but it was not one of the ones we knew
        # then just reproduce the argument
      } elsif ($isAccent) {
        $commandArgs =~ s/[\s\-~]//g;
        $commandArgs =~ s/[^a-z0-9 ]//ig;
        $purified .= $commandArgs;
        # else replace as if we were on level 1
      } else {
        $letter =~ s/[\s\-~]/ /g;
        $letter =~ s/[^a-z0-9 ]//ig;
        $purified .= $letter;
      }

      # on level 1+, we replace all the - and ~s with spaces, and apart from those keep only spaces
    } else {
      $letter =~ s/[\s\-~]/ /g;
      $letter =~ s/[^a-z0-9 ]//ig;
      $purified .= $letter;
    }
  }
  return $purified;
}

1;
