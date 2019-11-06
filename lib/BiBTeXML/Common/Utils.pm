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
our @EXPORT = qw(
  &escapeString &startsWith
);

# escapes a string so that it can be used as a perl literal
sub escapeString {
    my ($str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/'/\\'/g;
    return "'$str'";
}

# check if $haystack starts with $needle
sub startsWith {
    my ( $haystack, $needle ) = @_;
    return substr( $haystack, 0, length($needle) ) eq $needle;
}

1;
