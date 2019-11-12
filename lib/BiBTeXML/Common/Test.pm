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

use Test::More;
use File::Temp qw(tempfile);
use BiBTeXML::Runner;
use BiBTeXML::Common::Utils qw(slurp);

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
  &integrationTest
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

# represents a full test of the BiBTeXML steps
sub integrationTest {
    my ( $name, $path, $citesIn, $macroIn ) = @_;

    # resolve paths to input and output
    $path = File::Spec->catfile('t', 'fixtures', 'integration', $path);
    my $bstIn = File::Spec->catfile($path, 'input.bst');
    my $bibfiles = [File::Spec->catfile($path, 'input.bib')];
    my $resultOut = File::Spec->catfile($path, 'output.bbl');

    subtest "$name" => sub {
        plan tests => 4;

        # create a reader for the bst file
        my $reader = BiBTeXML::Common::StreamReader->new();
        $reader->openFile($bstIn);

        # compile it into the perl target
        my ( $code, $compiled ) =
          createCompile( 'Perl', $reader, \&note, $bstIn );

        # check that the code compiled without problems
        is( $code, 0, 'compilation went without problems' );
        return if $code ne 0;

        # split citations (to see what we want to have cited)
        my @citations = split( /,/, $citesIn );

        # create a run
        my ($output) = File::Temp->new( UNLINK => 1, SUFFIX => '.tex' );
        my ( $status, $runcode ) =
          createRun( $compiled, $bibfiles, [@citations], $macroIn, \&note,
            $output, );

        # check that preparing the run went ok
        is( $status, 0, 'run preparation went ok' );
        return if $code ne 0;

        # run the run
        $status = &{$runcode}();
        is( $status, 0, 'running went ok' );

        # check that we compiled the expected output
        is( slurp($output), slurp($resultOut),
            'compilation returned expected result' );
    };
}

1;
