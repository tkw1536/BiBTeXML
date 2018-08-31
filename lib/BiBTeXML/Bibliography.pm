# /=====================================================================\ #
# |  BiBTeXML::Bibliography                                             | #
# | .bib file parsing & evaluation                                      | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Bibliography;
use strict;
use warnings;

use BiBTeXML::Bibliography::BibEntry;
use BiBTeXML::Bibliography::BibTag;
use BiBTeXML::Bibliography::BibString;
use BiBTeXML::Bibliography::BibParser;

use base qw(Exporter);
our @EXPORT = qw(
  &BibEntry &BibTag &BibString
  &readFile &readEntry
  &readLiteral &readBrace &readQuote
);

sub BibEntry  { BiBTeXML::Bibliography::BibEntry->new(@_); }
sub BibTag    { BiBTeXML::Bibliography::BibTag->new(@_); }
sub BibString { BiBTeXML::Bibliography::BibString->new(@_); }

1;
