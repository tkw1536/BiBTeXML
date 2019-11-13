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
  &slurp &puts
  &printBiBTeXBuffer &finalizeBiBTeXBuffer
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

# TODO: Refactor the BiBTeX Buffer into a stream or custom class

# printBiBTeXBuffer prints $string to $stream using hard-wrapping
# as implemented by BibTeX. In order to maintain state across different
# calls of printBiBTeXBuffer, use $state = printBiBTeXBuffer(..., $state);
sub printBiBTeXBuffer {
    my ($stream, $string, $state) = @_;
    my $bibtex_hardwrap = 79;

    $state = [0, 0, ''] unless defined($state);
    my ($counter, $skipSpaces, $rest) = @{$state};

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
            $rest=~s/\s+$//; # trim right-most spaces
            print $stream "$rest\n";
            $rest = '';
            $counter = 0;

        # we had too many characters and there is a space
        } elsif (($counter >= $bibtex_hardwrap) && ($char =~ /\s/)) {
            $rest=~s/\s+$//; # trim right-most spaces
            print $stream "$rest\n  ";
            $rest = '';
            $counter = 2;
            $skipSpaces = 1;
        } else {
            $rest .= $char;
        }
    }

    return [$counter, $skipSpaces, $rest];
}

sub finalizeBiBTeXBuffer {
    my ($stream, $state) = @_;
    return unless defined($stream);

    # print whatever is left in the buffer
    my ($counter, $skipSpaces, $rest) = @{$state};
    return unless $rest;
    print $stream $rest;
}

1;
