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

use Encode;

use base qw(Exporter);
our @EXPORT = qw(
  &escapeString &startsWith
  &slurp &puts &printWrappedBiBTeX
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

# read an entire file into a string
sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Can't open file $path: $!";
    my $file_content = do { local $/; binmode $fh; <$fh> };
    close($fh);
    $file_content =~ s/(?:\015\012|\015|\012)/\n/sg;
    return decode( 'utf-8', $file_content );
}

# write an entire file into a string
sub puts {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Can't open file $path: $!";
    print $fh encode( 'utf-8', $content );
    close $fh;
}

# printWrappedBibtex prints $string to $stream using hard-wrapping
# as implemented by BibTeX. In order to maintain state across different
# calls of printWrappedBiBTeX, use $state = printWrappedBiBTeX(..., $state);
sub printWrappedBiBTeX {
    my ($stream, $string, $state) = @_;
    my $bibtex_hardwrap = 79;

    $state = [0, 0] unless defined($state);
    my ($counter, $skipSpaces) = @{$state};

    my @chars = split("", $string);
    my ($char);
    foreach $char (@chars) {
        # if we need to skip spaces, don't output anything
        next if $skipSpaces && ($char =~ /\s/);

        # increase the counter and reset skipSpaces
        $skipSpaces = 0;
        $counter++;

        # character is a newline => reset the counter
        if ($char eq "\n") {
            $counter = 0;

        # we had too many characters and there is a space
        } elsif (($counter >= $bibtex_hardwrap) && ($char =~ /\s/)) {
            $counter = 0;
            print $stream "\n"; # TODO: Figure out why BiBTeX inserts an extra space
            print $stream "  ";
            $skipSpaces = 1;
            next;
        }

        print $stream $char;
    }

    return [$counter, $skipSpaces];
}

1;
