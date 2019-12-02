# /=====================================================================\ #
# |  BiBTeXML::Runner                                                   | #
# | Instantiates the runtime and runs a compiles .bst file               | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runner;
use strict;
use warnings;

use Encode;

use BiBTeXML::BibStyle;
use BiBTeXML::Compiler;
use BiBTeXML::Runtime::Config;
use BiBTeXML::Runtime::Utils;
use BiBTeXML::Common::StreamReader;
use BiBTeXML::Runtime::Buffer;

use BiBTeXML::Compiler::Target;

use Time::HiRes qw(time);

use Module::Load;

use base qw(Exporter);
our @EXPORT = qw(
  &createCompile
  &createRun
);

# compiles a given bst file
# returns 0, <compiled_code> if successfull or error code, undef
# if not
# - error + log messages are sent to the $logger sub
# Error codes are:
# - 2: (Unused)
# - 3: (Unused)
# - 4: Unable to parse bst-file
# - 5: Unable to compile bst-file
sub createCompile {
    my ( $reader, $logger, $name ) = @_;

    # parse the file and print how long it took
    my $startParse = time;
    my ( $parsed, $parseError ) = eval { readFile($reader) } or do {
        $logger->("Unable to parse $name. \n");
        $logger->($@);
        return 4;
    };
    my $durationParse = time - $startParse;
    $reader->finalize;

    # throw an error, or a message how long it took
    if ( defined($parseError) ) {
        $logger->("Unable to parse $name. \n");
        $logger->($parseError);
        return 4, undef;
    }
    $logger->("Parsed   $name in $durationParse seconds. \n");

    # compile the file and print how long it took
    my $startCompile = time;
    my ( $compile, $compileError ) =
      eval { compileProgram( "BiBTeXML::Compiler::Target", $parsed, $name ) } or do {
        $logger->("Unable to compile $name. \n");
        $logger->($@);
        return 5, undef;
      };
    my $durationCompile = time - $startCompile;

    # throw an error, or a message how long it took
    if ( defined($compileError) ) {
        $logger->("Unable to compile $name. \n");
        $logger->($compileError);
        return 5, undef;
    }
    $logger->("Compiled $name in $durationCompile seconds. \n");

    # return the parsed code
    return 0, $compile;
}

# creates a sub that can be called to execute a given input file
# and directs output to a given output file or stdout
# returns 0, <code> if successfull or error code, undef if not
# - error + log messages are sent to the $logger sub
# - output is printed into the file OUTPUT, or STDOUT if undef.
# Error codes are:
# - 2: Unable to find compiled bstfile
# - 3: Error in compiled bstfile
# - 4: Unable to find bibfile
# - 5: Error opening outfile
# - 6: something went wrong at runtime
sub createRun {
    my ( $code, $bibfiles, $cites, $macro, $logger, $output, $wrapEnabled ) =
      @_;

    # run the code in the input
    $code = eval $code;
    unless ( defined($code) ) {
        $logger->($@);
        return 3, undef;
    }

    # check that all input files exist
    my $bf;
    foreach $bf (@$bibfiles) {
        unless ( -e $bf ) {
            $logger->("Unable to find bibfile $bf");
            return 4, undef;
        }
    }

    # create stream readers
    my $reader;
    my @readers = ();
    foreach $bf (@$bibfiles) {
        $reader = BiBTeXML::Common::StreamReader->new();
        $reader->openFile($bf);
        push( @readers, $reader );
    }

    # create an output buffer
    my $ofh;
    if ( defined($output) ) {
        open( $ofh, ">", $output );
    }
    else {
        $ofh = *STDOUT;
    }
    unless ( defined($ofh) ) {
        $logger->("Unable to find $output");
        return 5, undef;
    }
    my $buffer = BiBTeXML::Runtime::Buffer->new( $ofh, $wrapEnabled, $macro );

    # Create a configuration that optionally wraps things inside a macro
    my $config = BiBTeXML::Runtime::Config->new(
        undef, $buffer,
        sub {
            $logger->( fmtLogMessage(@_) . "\n" );
        },
        [@readers],
        [@$cites]
    );

    return 0, sub {
        my ( $ok, $msg ) = $config->run($code);
        $logger->($msg) if defined($msg);
        $buffer->finalize;
        return 6 unless $ok;
        return 0;
    }
}
