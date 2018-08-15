# /=====================================================================\ #
# |  BibTeXML::Bibliography::BibParser                                  | #
# | A Parser for .bib files                                             | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BibTeXML::Bibliography::BibParser;
use strict;
use warnings;

use BibTeXML::Bibliography::BibString;
use BibTeXML::Bibliography::BibTag;
use BibTeXML::Bibliography::BibEntry;

use base qw(Exporter);
our @EXPORT = (
  qw( &readFile &readEntry &readQuote ),
  qw( &readLiteral &readBrace &readQuote ),
  qw( &getLocationString),
);

# ======================================================================= #
# Characters & General Stuff
# ======================================================================= #

# checks that a character is not a special literal
sub isNotSpecialLiteral {
  my ($char) = @_;
  return ($char ne '{') && ($char ne '}') && ($char ne '=') && ($char ne '#') && ($char ne ',');
}

# checks that a character does not terminate a space character
# and is also not a space
sub isNotSpecialSpaceLiteral {
  my ($char) = @_;
  return ($char =~ /[^\s]/) && ($char ne '{') && ($char ne '}') && ($char ne '=') && ($char ne '#') && ($char ne ',');
}

# format an error message for the user
sub getLocationString {
  my ($reader) = @_;
  my ($row, $col) = $reader->getPosition;
  return ' near line ' . $row . ' column ' . $col;
}

# ======================================================================= #
# Parsing a file
# ======================================================================= #

# parses an entire .bib file into a collection of entries.
# return [@entries], [@errors]
sub readFile {
  my ($reader) = @_;

  my @entries = ();
  my @errors  = ();

  my ($entry, $error) = readEntry($reader);

  while (defined($entry) || defined($error)) {
    if (defined($entry)) {
      push(@entries, $entry);
    } else {
      push(@errors, $error);
    }

    ($entry, $error) = readEntry($reader);
  }

  return ([@entries], [@errors]);
}

# ======================================================================= #
# Parsing an entry
# ======================================================================= #

# reads the next bib entry from a source file and return it.
# may return a string in case of an error
sub readEntry {
  my ($reader) = @_;

  # skip ahead until we have an '@' sign
  my $prev = ' ';
  $reader->readCharWhile(sub {
      # if the previous character was a space (perhaps linebreak)
      # then start an entry with an '@' sign.
      if ($prev =~ /\s/) {
        return !($_[0] eq '@');
      }

      # else keep reading chars
      $prev = $_[0];
      return 1;
  });

  # read an @ sign
  my ($sr, $sc) = $reader->getPosition;
  my ($at) = $reader->readChar;
  return undef, undef unless defined($at);
  return undef, 'expected to find an "@"' . getLocationString($reader) unless $at eq '@';

  # read the type
  my ($type, $typeError) = readLiteral($reader);
  return $type, $typeError unless defined($type);
  return undef, 'expected a non-empty name' . getLocationString($reader) unless $type->getValue;

  # read opening brace (for tags)
  my ($obrace) = $reader->readChar;
  return undef, 'expected an "{"' . getLocationString($reader) unless defined($obrace) && $obrace eq '{';

  my @tags = ();

  my ($char, $tag, $tagError);

  while (1) {
    $reader->eatSpaces;
    ($char) = $reader->peekChar;
    return undef, 'Unexpected end of input while reading entry' . getLocationString($reader) unless defined($char);

    # if we have a comma, we just need the next tag
    # TODO: Ignores multiple following commas
    # TODO: What happens if we have a comma in the first position?
    if ($char eq ',') {
      $reader->eatChar;

      # if we have a closing brace, we are done
    } elsif ($char eq '}') {
      $reader->eatChar;
      last;

      # else push a tag (if we have one)
    } else {
      ($tag, $tagError) = readTag($reader);
      return $tag, $tagError if defined($tagError);
      push(@tags, $tag) if defined($tag);
    }
  }

  my ($er, $ec) = $reader->getPosition;
  return BibTeXML::Bibliography::BibEntry->new($type, [@tags], [$sr, $sc, $er, $ec]);
}

# ======================================================================= #
# Parsing a Tag
# ======================================================================= #

# reads a single tag from the input
# with an optional name and content
sub readTag {
  my ($reader) = @_;

  # skip spaces and start reading a tag
  $reader->eatSpaces;
  my ($sr, $sc) = $reader->getPosition;
  my ($er, $ec) = ($sr, $sc);

  # if we only have a closing brace
  # we may have tried to read a closing brace
  # so return undef and also no error.
  my ($char) = $reader->peekChar;
  return undef, 'Unexpected end of input while reading tag' . getLocationString($reader) unless defined($char);

  if ($char eq '}' or $char eq ',') {
    return undef, undef;
  }

  # STATE: What we are allowed to read next
  my $mayStringNext = 1;
  my $mayConcatNext = 0;
  my $mayEqualNext  = 0;

  # results and if we had an error
  my @content = ();
  my ($value, $valueError);
  my $hadEqualSign = 0;

  # read until we encounter a , or a closing brace
  while ($char ne ',' && $char ne '}') {

    # if we have an equals sign, remember that we had one
    # and allow only strings next (i.e. the value)
    if ($char eq '=') {
      return undef, 'Unexpected "="' . getLocationString($reader) unless $mayEqualNext;
      $reader->eatChar;

      $hadEqualSign = 1;

      $mayStringNext = 1;
      $mayConcatNext = 0;
      $mayEqualNext  = 0;

      # if we have a concat, allow only strings (i.e. the value) next
    } elsif ($char eq '#') {
      return undef, 'Unexpected "#"' . getLocationString($reader) unless $mayConcatNext;
      $reader->eatChar;

      $mayStringNext = 1;
      $mayConcatNext = 0;
      $mayEqualNext  = 0;

      # if we had a quote, allow only a concat next
    } elsif ($char eq '"') {
      return undef, 'Unexpected \'"\'' . getLocationString($reader) unless $mayStringNext;

      ($value, $valueError) = readQuote($reader);
      return $value, $valueError unless defined($value);
      push(@content, $value);

      $mayStringNext = 0;
      $mayConcatNext = 1;
      $mayEqualNext  = 0;

      # if we had a brace, allow only a concat next
    } elsif ($char eq '{') {
      return undef, 'Unexpected \'{\'' . getLocationString($reader) unless $mayStringNext;

      ($value, $valueError) = readBrace($reader);
      return $value, $valueError unless defined($value);
      push(@content, $value);

      $mayStringNext = 0;
      $mayConcatNext = 0;
      $mayEqualNext  = !$hadEqualSign;

      # if we have a literal, allow concat and equals next (unless we already had)
    } else {
      return undef, 'Unexpected start of literal' . getLocationString($reader) unless $mayStringNext;

      ($value, $valueError) = readLiteral($reader);
      return $value, $valueError unless defined($value);
      push(@content, $value);

      $mayStringNext = 0;
      $mayConcatNext = 1;
      $mayEqualNext  = !$hadEqualSign;
    }

    ($er, $ec) = $reader->getPosition;
    $reader->eatSpaces;

    ($char) = $reader->peekChar;
    return undef, 'Unexpected end of input while reading tag' . getLocationString($reader) unless defined($char);
  }

  # if we had an equal sign, shift that value
  my $name;
  $name = shift(@content) if ($hadEqualSign);

  return BibTeXML::Bibliography::BibTag->new($name, [@content], [($sr, $sc, $er, $ec)]);
}

# ======================================================================= #
# Parsing Literals, Quotes & Braces
# ======================================================================= #

# read a keyword until the next special character
# skips spaces at the end, but not at the beginning
sub readLiteral {
  my ($reader) = @_;

  # get the starting position
  my ($sr, $sc) = $reader->getPosition;
  my ($er, $ec) = ($sr, $sc);

  my $keyword = '';
  my $spaces  = '';

  # look at the next character and break if it is a special
  my ($char, $line, $col, $eof) = $reader->readChar;
  return undef, 'Unexpected end of input in literal' . getLocationString($reader) unless defined($char);

  my $isNotSpecialSpaceLiteral = \&isNotSpecialSpaceLiteral;

  # iterate over sequential non-space sequences
  while (isNotSpecialLiteral($char)) {
    # add spaces from the last round (if any)
    $keyword .= $spaces . $char . $reader->readCharWhile($isNotSpecialSpaceLiteral);

    # record possible end position and skip more spaces
    ($er, $ec) = $reader->getPosition;
    $spaces = $reader->readSpaces;

    # look at the next character and break if it is a special
    ($char, $line, $col, $eof) = $reader->readChar;
    return undef, 'Unexpected end of input in literal' . getLocationString($reader) unless defined($char);
  }

  # unread the character that isn't part of the special literal and return
  $reader->unreadChar($char, $line, $col, $eof);
  return BibTeXML::Bibliography::BibString->new('LITERAL', $keyword, [($sr, $sc, $er, $ec)]);
}

# read a string of balanced braces from the input
# does not skip any spaces before or after
sub readBrace {
  my ($reader) = @_;

  # read the first bracket, or die if we are at the end
  my ($char, $line, $col, $eof) = $reader->readChar;
  return undef, 'expected to find an "{"' . getLocationString($reader) unless defined($char) && $char eq '{';

  # record the starting position of the bracket
  my ($sr, $sc) = ($line, $col);

  # setup where we are
  my $result = '';
  my $level  = 1;
  $char = '';

  while ($level) {
    # add the previous character, and read the next one.
    $result .= $char;
    ($char, $line, $col, $eof) = $reader->readChar;
    return undef, 'Unexpected end of input in quote' . getLocationString($reader) if $eof;

    # keep count of what level we are in
    if ($char eq '{') {
      $level++;
    } elsif ($char eq '}') {
      $level--;
    }
  }

  # we can add a +1 here, because we did not read a \n
  return BibTeXML::Bibliography::BibString->new('BRACKET', $result, [($sr, $sc, $line, $col + 1)]);
}

# read a quoted quote from reader
# does not skip any spaces
sub readQuote {
  my ($reader) = @_;

  # read the first quote, or die if we are at the end
  my ($char, $line, $col, $eof) = $reader->readChar;
  return undef, 'expected to find an \'"\'' . getLocationString($reader) unless defined($char) && $char eq '"';

  # record the starting position of the bracket
  my ($sr, $sc) = ($line, $col);

  my $result = '';
  my $level  = 0;
  while (1) {
    ($char, $line, $col, $eof) = $reader->readChar;
    return undef, 'Unexpected end of input in quote' . getLocationString($reader) if $eof;

    # if we find a {, or a }, keep track of levels, and don't do anything inside
    if ($char eq '"') {
      last unless $level;
    } elsif ($char eq '{') {
      $level++;
    } elsif ($char eq '}') {
      $level--;
    }

    $result .= $char;
  }

  # we can add a +1 here, because we did not read a \n
  return BibTeXML::Bibliography::BibString->new('QUOTE', $result, [($sr, $sc, $line, $col + 1)]);
}
1;
