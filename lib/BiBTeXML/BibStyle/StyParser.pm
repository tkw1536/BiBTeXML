# /=====================================================================\ #
# |  BiBTeXML::Bibliography::BibParser                                  | #
# | A Parser for .bib files                                             | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::BibStyle::StyParser;
use strict;
use warnings;

use BiBTeXML::BibStyle::StyString;

# format an error message for the user
sub getLocationString {
  my ($reader) = @_;
  my ($row, $col) = $reader->getPosition;
  return ' near line ' . $row . ' column ' . $col;
}

# ======================================================================= #
# Parsing quotes literals and braces
# ======================================================================= #

# read any valid code from the sty file
sub readAny {
  my ($reader) = @_;

  my ($char, $sr, $sc) = $reader->peekChar;
  return undef, 'Unexpected end of input while reading' . getLocationString($reader) unless defined($char);

  if ($char eq '#') {
    return readNumber($reader);
  } elsif ($char eq "'") {
    return readReference($reader);
  } elsif ($char eq '"') {
    return readQuote($reader);
  } elsif ($char eq '{') {
    return readBlock($reader);
  } else {
    return readLiteral($reader);
  }
}

sub readBlock {
  my ($reader) = @_;

  # read the opening brace
  my ($char, $sr, $sc) = $reader->readChar;
  return 'expected "{" while reading block' . getLocationString($reader) unless defined($char) && $char eq '{';

  my @values = ();
  my ($value, $valueError, $er, $ec);

  # if the next char is '}', finish
  ($char, $er, $ec) = $reader->peekChar;
  return undef, 'Unexpected end of input while reading block' . getLocationString($reader) unless defined($char);

  # read until we find a closing brace
  while ($char ne '}') {

    ($value, $valueError) = readAny($reader);
    return $value, $valueError if defined($valueError);
    push(@values, $value);

    # skip all the spaces and read the next character
    $reader->eatSpaces;
    ($char, $er, $ec) = $reader->peekChar;
    return undef, 'Unexpected end of input while reading block' . getLocationString($reader) unless defined($char);
  }

  $reader->eatChar;
  # we can add +1, because we did not read a \n
  return BiBTeXML::BibStyle::StyString->new('BLOCK', [@values], [($sr, $sc, $er, $ec + 1)]);
}

sub readNumber {
  my ($reader) = @_;

  # read anything that's not a space
  my ($char, $sr, $sc) = $reader->readChar;
  return undef, 'expected "#" while reading number' . getLocationString($reader) unless defined($char) && $char eq '#';

  my ($literal, $er, $ec) = $reader->readCharWhile(sub { $_[0] =~ /\d/; });
  return undef, 'expected a non-empty number' . getLocationString($reader) unless $literal ne "";

  return BiBTeXML::BibStyle::StyString->new('NUMBER', $literal + 0, [($sr, $sc, $er, $ec)]);
}

sub readReference {
  my ($reader) = @_;

  my ($char, $sr, $sc) = $reader->readChar;
  return undef, 'expected "\'" while reading reference' . getLocationString($reader) unless defined($char) && $char eq "'";

  # read anything that's not a space and not the end of a block
  my ($reference, $er, $ec) = $reader->readCharWhile(sub { $_[0] =~ /[^\s\}]/; });
  return undef, 'expected a non-empty argument' . getLocationString($reader) unless $reference ne "";

  return BiBTeXML::BibStyle::StyString->new('REFERENCE', $reference, [($sr, $sc, $er, $ec)]);
}

# Reads a literal, delimited by spaces, from the input
sub readLiteral {
  my ($reader) = @_;

  # read anything that's not a space or the end of a block
  my ($sr, $sc) = $reader->getPosition;
  my ($literal, $er, $ec) = $reader->readCharWhile(sub { $_[0] =~ /[^\s\}]/; });
  return undef, 'expected a non-empty literal' . getLocationString($reader) unless $literal;

  return BiBTeXML::BibStyle::StyString->new('LITERAL', $literal, [($sr, $sc, $er, $ec)]);
}

# read a quoted quote from reader
# does not skip any spaces
sub readQuote {
  my ($reader) = @_;

  # read the first quote, or die if we are at the end
  my ($char, $line, $col, $eof) = $reader->readChar;
  return undef, 'expected to find an \'"\'' . getLocationString($reader) unless defined($char) && $char eq '"';

  # record the starting position and read until the next quote
  my ($sr, $sc) = ($line, $col);
  my ($result) = $reader->readCharWhile(sub { $_[0] =~ /[^"]/ });
  return undef, 'Unexpected end of input in quote' . getLocationString($reader) if $eof;

  # read the end quote, or die if we are at the end
  ($char, $line, $col, $eof) = $reader->readChar;
  return undef, 'expected to find an \'"\'' . getLocationString($reader) unless defined($char) && $char eq '"';

  # we can add a +1 here, because we did not read a \n
  return BiBTeXML::BibStyle::StyString->new('QUOTE', $result, [($sr, $sc, $line, $col + 1)]);
}
1;
