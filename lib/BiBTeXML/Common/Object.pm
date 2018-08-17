# /=====================================================================\ #
# |  BiBTeXML::Common::Object                                           | #
# | Common function for BiBTeXML objects                                | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Common::Object;
use strict;
use warnings;

# gets the starting position of this object
# a quadruple ($startRow, $startColumn, $endRow, $endColumn)
# row-indexes are one-based, column-indexes zero-based
# the start position is inclusive, the end position is not
# never includes any whitespace in positioning
sub getSource {
  my ($self) = @_;
  return $$self{source};
}

# checks if this object equals another object
sub equals {
  my ($self, $other) = @_;
  $other = ref $other ? $other->stringify : $other;
  return $self->stringify eq $other;
}

1;
