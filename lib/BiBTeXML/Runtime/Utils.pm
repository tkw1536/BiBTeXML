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
  qw( &splitLetters &parseAccent ),
  qw( &changeCase &getCase &abbrevName),
  qw( &splitNameWords &splitNameParts &formatNamePart &formatName ),
  qw( &splitNames &numNames ),
  # TODO: Implement purify$
  qw( &textSubstring ),
  qw( &textLength ),
  qw( &textPrefix ),
  qw( &textWidth ),
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
# and if so returns (1, $outerPrefix, $innerPrefix, $content, $innerSuffix, $outerSuffix)
# - $outerPrefix is a string prefixing the accent, but not belonging to it at all
# - $innerPrefix is the part of the accent that is not-case sensitive
# - $content is the case-sensitive part of the accent
# - $innerSuffix is a string following the accent, and belonging to it
# - $outerSuffix is a string following the accent, but not belonging to it at all
# the following inequality holds:
# $string eq $outerPrefix . $innerPrefix . $content . $innerSuffix . $outerSuffix
# if not returns (0, '', '', $string, '', '')
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

    my ($prefix, $suffix);

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
        # everything if we do not have any spaces or brackets
      } else {
        $accent = $content;
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
    return 1, $outerPrefix, $innerPrefix, $accent, $innerSuffix, $outerSuffix;

    # this isn't an accent -- what did you pass?
  } else {
    return 0, '', '', $string, '', '';
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
  my ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix);

  # iterate over each level
  foreach $letter (@$letters) {
    $level = shift(@$levels);

    # change case if we are on level 0
    if ($level eq 0) {
      ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix) = parseAccent($letter);

      # upper case (or first letter of t)
      if ($spec eq 'u' or ($spec eq 't' && $index eq 1)) {
        # special case: \ss is the only accent to be changed into a non-accent
        if ($isAccent && substr($iPrefix, -1) eq '\\' && $accent eq 'ss') {
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
  my ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix, $letter, $level);
  foreach $letter (@$letters) {
    $level = shift(@$levels);

    # on level 0, check for accents
    if (defined($level) && $level eq 0) {

      # parse the accent
      ($isAccent, $oPrefix, $iPrefix, $accent, $iSuffix, $oSuffix) = parseAccent($string);

      # if we have a command in $accent, add the width of that 'character'
      if ($isAccent && substr($iPrefix, -1) eq '\\') {
        $width += characterWidth('\\' . $accent);

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
# which has to be either exactly one character or start with '\\'.
sub characterWidth {
  my ($char) = @_;
  my $width;

  # if we have a single character
  # return the width of that character or 0
  if (length($char) eq 1) {
    $width = $WIDTHS{ ord $char };
    return $width if defined($width);
    return 0;
  }

  # trim off the leading '\\'
  $char = substr($char, 1);

  # return the width of that accent if defined
  $width = $WIDTHS{$char};
  return $width if defined($width);

  # width of base + width of character itself
  return ($WIDTHS{ substr($char, 1, 1) } || 0) + characterWidth(substr($char, 2, 1));
}

# returns the prefix of length $length of a string
# implements substring$
sub textSubstring {
  my ($string, $start, $length) = @_;
  return substr($string, $start > 0 ? $start - 1 : $start - 2, $length);
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
  while (defined($character = shift(@characters))) {
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
  while (defined($character = shift(@characters))) {
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
  my $seperator;
  while (defined($buffer = shift(@result))) {
    # split off everything except for the first seperator
    $buffer =~ s/([\s~-])[\s~-]*$/$1/;

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
    while (defined($word = shift(@prec))) {
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

# abbreviates a name
sub abbrevName {
  my ($string) = @_;
  my ($letters, $levels) = splitLetters($string);

  my ($letter, $isAccent);
  while (defined($letter = shift(@$letters))) {

    # if it is an accent, return the letter as a whole
    ($isAccent) = parseAccent($letter);
    return $letter if $isAccent;

    # else, return the first letter of it
    if ($letter =~ /[a-z]/i) {
      ($letter) = ($letter =~ m/([a-z])/i);
      return $letter;
    }
  }

  # we got no letter at all
  # not sure what to return here
  return undef;
}

# formats a single name part according to a specification by BibTeX
sub formatNamePart {
  my ($parts, $short, $seperator, $post) = @_;
  my $result = '';

  # if we have an explicit seperator, use it
  # and trim off all the existing ones
  if (defined($seperator)) {
    my @names = map { my $name = $_; $name =~ s/([\s~-]+)$//; $name; } @$parts;
    @names = map { abbrevName($_) } @names if $short;
    $result = join($seperator, @names);
  } else {
    my ($name, $seperator, $index) = ('', '', 0);
    my $lastIndex = scalar(@$parts) - 1;

    # iterate through all the names
    foreach $name (@$parts) {
      # extract name and seperator
      ($seperator) = ($name =~ m/([\s~-]+)$/);
      $seperator = ' ' unless defined($seperator); # if a seperator is missing, assume it is ' ' just to be safe
      $name =~ s/([\s~-]+)$//;

      # add the current token to the result
      $result .= $short ? abbrevName($name) : $name;
      $result .= '.' if ($short && $index ne $lastIndex);

      # first index (if we have at least three tokens, and the first one is 1 or 2 characters)
      if ($index eq 0 && $lastIndex > 2 && ($short or textLength($name) <= 2)) {
        $result .= ($seperator =~ m/^(\s+)$/) ? '~' : substr($seperator, 0, 1);
        # insert a '~' for the next to last token
      } elsif ($index eq $lastIndex - 1) {
        $result .= ($seperator =~ m/^(\s+)$/) ? '~' : substr($seperator, 0, 1);

        # all non-final tokens: insert the (first) seperator token
      } elsif ($index ne $lastIndex) {
        $result .= substr($seperator, 0, 1);
      }

      $index++;
    }
  }

  # if we end with '~~', end with a single '~'
  if ($post =~ /~~$/) {
    $post =~ s/~~$/~/;

    # if we end with non-double ~, end with a space
  } elsif ($post =~ /~$/) {
    $post =~ s/~$/ /;
  }
  return $result . $post;
}

# formats a BiBTeX name according to a specification
# implements format.name$
sub formatName {
  my ($name, $spec) = @_;

  # split the name into pieces, we will need this during formatting
  my ($first, $von, $jr, $last) = splitNameParts($name);
  my @currp;

  # the specification, split into characters
  my @characters = split(//, $spec);
  my ($result, $partresult, $character);
  my ($letter, $short, $seperator, $post);
  my ($level);

  while (defined($character = shift(@characters))) {

    if ($character eq '{') {

      # iterate through the subpattern
      $partresult = '';
      while ($character = shift(@characters)) {
        # we finally hit the alphabetic character
        if ($character =~ /[a-z]/i) {
          $letter = $character;

          # check which part we have
          if ($letter eq 'f') {
            @currp = @$first;
          } elsif ($letter eq 'v') {
            @currp = @$von;
          } elsif ($letter eq 'j') {
            @currp = @$jr;
          } elsif ($letter eq 'l') {
            @currp = @$last;
          } else {
            return undef, 'Invalid name part: ' . $letter;
          }

          # read the next pattern
          $character = shift(@characters);
          return undef, 'Unexpected end of pattern' unless defined($character);

          # if we have the letter repeated, it is a long pattern
          if ($character =~ /[a-z]/i) {
            return undef, "Unexpected letter $character, $letter should be repeated. " unless $character eq $letter;
            $short     = 0;
            $character = shift(@characters);
            return 'Unexpected end of pattern' unless defined($character);

            # else if must be a short pattern.
          } else {
            $short = 1;
          }

          # if we have a '{', read the seperator
          $seperator = undef;
          if ($character eq '{') {
            $level     = 1;
            $seperator = '';
            while (defined($character = shift(@characters))) {
              $level++ if $character eq '{';
              $level-- if $character eq '}';
              last     if $level eq 0;
              $seperator .= $character;
            }
          } else {
            unshift(@characters, $character);
          }

          # read whatever comes next until we are balaned again
          # until the closing '}' brace
          $post  = '';
          $level = 1;
          while (defined($character = shift(@characters))) {
            $level++ if $character eq '{';
            $level-- if $character eq '}';
            last     if $level eq 0;
            $post .= $character;
          }

          # now format the current part according to what we read.
          if (scalar(@currp) eq 0) {
            $partresult = '';
          } else {
            my $r = formatNamePart([@currp], $short, $seperator, $post);
            $partresult .= $r;
          }
          last;

          # if we closed the part, without having anything alphabetic
          # then something weird is going on, so insert it literally.
        } elsif ($character eq '}') {
          $partresult = '{' . $partresult . '}';
          last;
          # if we do not have a letter
          # insert this part literally
        } else {
          $partresult .= $character;
        }
      }
      $result .= $partresult;

      # outside of a group
      # characters are inserted undonditionally
    } else {
      $result .= $character;
    }
  }

  return $result;
}
