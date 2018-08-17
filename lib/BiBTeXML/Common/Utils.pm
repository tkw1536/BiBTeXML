# /=====================================================================\ #
# |  BiBTeXML::Common::Utils                                            | #
# | Generic Utility Functions                                           | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Common::Utils;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = (
  qw( &escapeString ),
);

# escapes a string so that it can be used as a perl literal
sub escapeString {
  my ($str) = @_;
  $str =~ s/\\/\\\\/g;
  $str =~ s/'/\\'/g;
  return "'$str'";
}

1;
