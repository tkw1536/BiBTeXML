# /=====================================================================\ #
# |  BiBTeXML::Common::Test                                             | #
# | Utility Functions for test cases                                    | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Common::Test;
use strict;
use warnings;

use Encode;
use Time::HiRes qw(time);

use File::Basename qw(dirname);
use File::Spec;

use BiBTeXML::Common::Utils qw(slurp puts);

use base qw(Exporter);
our @EXPORT = qw(
  &fixture &slurp &puts &isResult
  &makeStringReader &makeFixtureReader
  &measureBegin &measureEnd
);

# gets the path to a mock fixture
sub fixture {
    File::Spec->join( dirname( shift(@_) ), 'fixtures', @_ );
}

# makes a BiBTeXML::Common::StreamReader to a fixed string
sub makeStringReader {
    my ( $content, $eat, $delimiter ) = @_;
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString( ( $eat ? ' ' : '' )
        . $content
          . ( defined($delimiter) ? $delimiter : ' ' ) );
    $reader->eatChar if $eat;

    return $reader;
}

# makes a BiBTeXML::Common::StreamReader to a fixture
sub makeFixtureReader {
    my $reader = BiBTeXML::Common::StreamReader->new();
    my $path   = fixture(@_);
    $reader->openFile( $path, "utf-8" );
    return ( $reader, $path );
}

# joins a list of objects by stringifying them
sub joinStrs {
    my @strs = map { $_->stringify; } @_;
    return join( "\n\n", @strs );
}

# starts a measurement
sub measureBegin {
    return time;
}

# ends a measurement
sub measureEnd {
    my ( $begin, $name ) = @_;
    my $duration = time - $begin;
    Test::More::diag("evaluated $name in $duration seconds");
}

sub isResult {
    my ( $results, $path, $message ) = @_;
    Test::More::is( joinStrs( @{$results} ), slurp("$path.txt"), $message );
}

1;
