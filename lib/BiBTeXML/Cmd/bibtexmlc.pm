# /=====================================================================\ #
# |  BiBTeXML::Cmd::bibtexmlc                                           | #
# | bibtexmlc entry point                                               | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Cmd::bibtexmlc;
use strict;
use warnings;

use Encode;
use Getopt::Long qw(GetOptionsFromArray);
use Module::Load;

use Time::HiRes qw(time);

use BiBTeXML::Common::StreamReader;
use BiBTeXML::BibStyle;
use BiBTeXML::Compiler;

sub main {
    shift(@_);    # remove the first argument

    my ( $target, $dest, $help ) = ( 'Perl', '', 0 );
    my $p = Getopt::Long::Parser->new;
    GetOptionsFromArray(
        \@_,
        "target=s"      => \$target,
        "destination=s" => \$dest,
        "help"          => \$help,
    ) or return usageAndExit(1);

    # if we requested help, or we had a wrong number of arguments, exit
    return usageAndExit(1) if scalar(@_) ne 1;
    return usageAndExit(0) if ($help);

    $target =
      ( index( $target, ':' ) != -1 )
      ? $target
      : "BiBTeXML::Compiler::Target::$target";
    $target = eval {
        load $target;
        "$target";
    } or do {
        print STDERR $@;
        return 2;
    };

    # check that the bst file exists
    my ($bstfile) = @_;
    unless ( -e $bstfile ) {
        print STDERR "Unable to find bstfile $bstfile\n";
        return 3;
    }

    # create a reader for the file
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openFile($bstfile);

    # parse the file and print how long it took
    my $startParse = time;
    my ( $parsed, $parseError ) = eval { readFile($reader) } or do {
        print STDERR "Unable to parse $bstfile. \n";
        print STDERR $@;
        return 4;
    };
    my $durationParse = time - $startParse;
    $reader->finalize;

    # throw an error, or a message how long it took
    if ( defined($parseError) ) {
        print STDERR "Unable to parse $bstfile. \n";
        print STDERR $parseError;
        return 4;
    }
    print STDERR "Parsed   $bstfile in $durationParse seconds. \n";

    # compile the file and print how long it took
    my $startCompile = time;
    my ( $compile, $compileError ) =
      eval { compileProgram( $target, $parsed, $bstfile ) } or do {
        print STDERR "Unable to compile $bstfile. \n";
        print STDERR $@;
        return 5;
      };
    my $durationCompile = time - $startCompile;

    # throw an error, or a message how long it took
    if ( defined($compileError) ) {
        print STDERR "Unable to compile $bstfile. \n";
        print STDERR $compileError;
        return 5;
    }
    print STDERR "Compiled $bstfile in $durationCompile seconds. \n";

    # Write the
    if ($dest) {
        my ( $path, $content ) = @_;
        open my $fh, '>', $dest or do {
            print STDERR "Unable to write to $dest";
            print STDERR $!;
            return 6;
        };
        print $fh encode( 'utf-8', $compile );
        close $fh;
        print STDERR "Wrote    $dest. \n";
        return 0;
    }

    print STDOUT $compile;
    print STDERR "Wrote    STDOUT. \n";
    return 0;
}

# helper function to print usage information and exit
sub usageAndExit {
    my ($code) = @_;
    print STDERR
      'bibtexmlc [--help] [--target $TARGET] [--destination $DEST] $BSTFILE'
      . "\n";
    return $code;
}

1;
