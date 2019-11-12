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

sub integrationTestPaths {
    my ($path) = @_;

    # resolve the path to the test case
    $path = File::Spec->catfile('t', 'fixtures', 'integration', $path);

    # read the citation specification file
    my $citesIn = [grep { /\S/ } split(/\n/,slurp(File::Spec->catfile($path, 'input_citations.spec')))];

    # read the macro specification file
    my $macroIn = slurp(File::Spec->catfile($path, 'input_macro.spec'));
    $macroIn =~ s/^\s+|\s+$//g;
    $macroIn = undef if $macroIn eq '';

    # hard-code input and output files
    # TODO: Alow multiple input files by having 'input_1.bib' etc using sorting
    my $bstIn = File::Spec->catfile($path, 'input.bst');
    my $bibfiles = [File::Spec->catfile($path, 'input.bib')];
    my $resultOut = File::Spec->catfile($path, 'output.bbl');

    return $bstIn, $bibfiles, $citesIn, $macroIn, $resultOut;
}

# represents a full test of the BiBTeXML steps
sub integrationTest {
    my ( $name, $path, $unused, $unusedB ) = @_;

    # resolve paths to input and output
    my ($bstIn, $bibfiles, $citesIn, $macroIn, $resultOut) = integrationTestPaths($path);

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

        # create a run
        my ($output) = File::Temp->new( UNLINK => 1, SUFFIX => '.tex' );
        my ( $status, $runcode ) =
          createRun( $compiled, $bibfiles, $citesIn, $macroIn, \&note,
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
