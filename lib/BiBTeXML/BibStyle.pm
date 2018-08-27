# /=====================================================================\ #
# |  BiBTeXML::BibStyle                                                 | #
# | .bst file parsing                                                   | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::BibStyle;

use BiBTeXML::BibStyle::StyCommand;
use BiBTeXML::BibStyle::StyString;
use BiBTeXML::BibStyle::StyParser;

use base qw(Exporter);
our @EXPORT = qw(
  &StyCommand &StyString
  &readFile &readCommand
  &readAny &readBlock
  &readNumber &readReference &readLiteral &readQuote
);

sub StyCommand { BiBTeXML::BibStyle::StyCommand->new(@_); }
sub StyString  { BiBTeXML::BibStyle::StyString->new(@_); }

1;
