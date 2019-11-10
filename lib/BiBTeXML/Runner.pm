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
# - error messages are printed directly to STDERR
# Error codes are:
# - 2: Unable to load compilation target
# - 3: (Unuused)
# - 4: Unable to parse bst-file
# - 5: Unable to compile bst-file
sub createCompile {
    my ( $target, $reader, $name ) = @_;

    # load the target
    $target =
      ( index( $target, ':' ) != -1 )
      ? $target
      : "BiBTeXML::Compiler::Target::$target";
    $target = eval {
        load $target;
        "$target";
    } or do {
        print STDERR $@;
        return 2, undef;
    };

    # parse the file and print how long it took
    my $startParse = time;
    my ( $parsed, $parseError ) = eval { readFile($reader) } or do {
        print STDERR "Unable to parse $name. \n";
        print STDERR $@;
        return 4;
    };
    my $durationParse = time - $startParse;
    $reader->finalize;

    # throw an error, or a message how long it took
    if ( defined($parseError) ) {
        print STDERR "Unable to parse $name. \n";
        print STDERR $parseError;
        return 4, undef;
    }
    print STDERR "Parsed   $name in $durationParse seconds. \n";

    # compile the file and print how long it took
    my $startCompile = time;
    my ( $compile, $compileError ) =
      eval { compileProgram( $target, $parsed, $name ) } or do {
        print STDERR "Unable to compile $name. \n";
        print STDERR $@;
        return 5, undef;
      };
    my $durationCompile = time - $startCompile;

    # throw an error, or a message how long it took
    if ( defined($compileError) ) {
        print STDERR "Unable to compile $name. \n";
        print STDERR $compileError;
        return 5, undef;
    }
    print STDERR "Compiled $name in $durationCompile seconds. \n";

    # return the parsed code
    return 0, $compile;
}

# creates a sub that can be called to execute a given input file
# and directs output to a given output file or stdout
# returns 0, <code> if successfull or error code, undef if not
# - error messages are printed to STDERR
# - output is printed into the file OUTPUT, or STDOUT if undef.
# Error codes are:
# - 2: Unable to find compiled bstfile
# - 3: Error in compiled bstfile
# - 4: Unable to find bibfile
# - 5: Error opening outfile
# - 6: something went wrong at runtime
sub createRun {
    my ( $code, $bibfiles, $cites, $macro, $output ) = @_;

    # run the code in the input
    $code = eval $code;
    unless ( defined($code) ) {
        print STDERR $@;
        return 3, undef;
    }

    # check that all input files exist
    my $bf;
    foreach $bf (@$bibfiles) {
        unless ( -e $bf ) {
            print STDERR "Unable to find bibfile $bf";
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

    # create an output file (or STDOUT)
    my $ofh;
    if ( defined($output) ) {
        open( $ofh, ">", $output );
    }
    else {
        $ofh = *STDOUT;
    }
    unless ( defined($ofh) ) {
        print STDERR "Unable to fine $output";
        return 5, undef;
    }

    # Create a configuration that optionally wraps things inside a macro
    my $config = BiBTeXML::Runtime::Config->new(
        undef,
        sub {
            print $ofh fmtOutputWithSourceMacro( @_, $macro );
        },
        sub {
            print STDERR fmtLogMessage(@_) . "\n";
        },
        [@readers],
        [@$cites]
    );

    return 0, sub {
        my ( $ok, $error ) = $config->run($code);
        print STDERR $error if defined $error;
        close($ofh);
        return 6 unless $ok;
        return 0;
    }
}
