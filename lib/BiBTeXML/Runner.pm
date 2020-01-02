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

# 'createCompile' compiles a '.bst' file and returns a pair $status, $compiledCode where:
# - $status indicates the compile status code
# - $compiledCode is a  string representing compiled code, or undef if compilation failed. 
# Status is one of:
# - 0: Everything ok
# - 4: Unable to parse bst-file
# - 5: Unable to compile bst-file
# Takes the following parameters:
# - $reader: An instance of 'BiBTeXML::Common::StreamReader' representing the stream to be read
# - $logger: A sub (or callable) taking a single string parameter used to output info and warning messages
# - $name: Name of the input file -- used only for log messages. 
sub createCompile {
    my ( $reader, $logger, $name ) = @_;

    # parse the file
    my ( $parsed, $parseError ) = eval { readFile($reader) } or do {
        $logger->("Unable to parse $name. \n");
        $logger->($@);
        return 4;
    };
    $reader->finalize;

    # throw an error, or a message how long it took
    if ( defined($parseError) ) {
        $logger->("Unable to parse $name. \n");
        $logger->($parseError);
        return 4, undef;
    }

    # compile the file
    my ( $compile, $compileError ) =
      eval { compileProgram( "BiBTeXML::Compiler::Target", $parsed, $name ) } or do {
        $logger->("Unable to compile $name. \n");
        $logger->($@);
        return 5, undef;
      };

    # throw an error, or a message how long it took
    if ( defined($compileError) ) {
        $logger->("Unable to compile $name. \n");
        $logger->($compileError);
        return 5, undef;
    }

    # return the parsed code
    return 0, $compile;
}

# 'createRun' prepares to run a compiled bst-file with a specific set of parameters. Returns a single value $callable
# which can be called parameter-less. This callable returns either 0 (everything ok) or 6 (something went wrong). 
# Takes the following parameters:
# - $code: A sub (or callable) representing the compiled code as e.g. returned by 'createCompile'
# - $bibfiles: A reference to a list of filenames representing the loaded '.bib' files. [TODO: Make this an array of BiBTeXML::Common::StreamReader s]
# - $cites: A reference to an array of cited keys. This may contain the special key '*' which indicates all keys should be cited. 
# - $macro: A macro to wrap all source references in, or undef if no such macro should be used. 
# - $logger: A sub (or callable) taking a single string parameter used to output info and warning messages
# - $output: A writeable file handle to print output into. 
# - $wrapEnabled: When set to 1, enable emulating BiBTeXs output wrapping. 
sub createRun {
    my ( $code, $bibfiles, $cites, $macro, $logger, $output, $wrapEnabled ) = @_;

    # ensure that utf-8 works
    binmode($output, ":utf8");

    # create an output buffer
    my $buffer = BiBTeXML::Runtime::Buffer->new( $output, $wrapEnabled, $macro );

    # Create a configuration that optionally wraps things inside a macro
    my $config = BiBTeXML::Runtime::Config->new(
        undef, $buffer,
        sub {
            $logger->( fmtLogMessage(@_) . "\n" );
        },
        [@$bibfiles],
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
