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

sub readArgument {
  my ($reader) = @_;

  # read anything that's not a space
  my ($char, $sr, $sc) = $reader->readChar;
  return 'expected "#" while reading argument' . getLocationString($reader) unless defined($char) && $char eq '#';

  my $literal = $reader->readCharWhile(sub { $_[0] =~ /\d/; });
  return undef, 'expected a non-empty argument' . getLocationString($reader) unless $literal ne "";
  my ($er, $ec) = $reader->getPosition;

  return BiBTeXML::BibStyle::StyString->new('ARGUMENT', $literal + 0, [($sr, $sc, $er, $ec)]);
}

# Reads a literal, delimited by spaces, from the input
sub readLiteral {
  my ($reader) = @_;

  # read anything that's not a space
  my ($sr, $sc) = $reader->getPosition;
  my $literal = $reader->readCharWhile(sub { $_[0] =~ /[^\s]/; });
  return undef, 'expected a non-empty literal' . getLocationString($reader) unless $literal;
  my ($er, $ec) = $reader->getPosition;

  return BiBTeXML::BibStyle::StyString->new('LITERAL', $literal, [($sr, $sc, $er, $ec)]);
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
  return BiBTeXML::BibStyle::StyString->new('QUOTE', $result, [($sr, $sc, $line, $col + 1)]);
}
1;
