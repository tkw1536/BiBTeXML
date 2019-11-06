# /=====================================================================\ #
# |  BiBTeXML::Cmd::bibtexmlr                                           | #
# | bibtexmlr entry point                                               | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Cmd::bibtexmlr;

use strict;
use warnings;

use Encode;
use Getopt::Long qw(GetOptionsFromArray);
use Module::Load;

use Time::HiRes qw(time);

use BiBTeXML::Runner;

sub main {
    shift(@_);    # remove the first argument

    my ( $output, $macro, $cites, $help ) = ( undef, undef, "*", 0 );
    GetOptionsFromArray(
        \@_,
        "destination=s" => \$output,
        "macro=s"       => \$macro,
        "cites=s"       => \$cites,
        "help"          => \$help,
    ) or return usageAndExit(1);

    # if we requested help, or we had a wrong number of arguments, exit
    return usageAndExit(1) if scalar(@_) eq 0;
    return usageAndExit(0) if ($help);

    # parse arguments
    my ( $input, @bibfiles ) = @_;

    # create a run
    my @citations = split( /,/, $cites );
    my ( $status, $code ) =
      createRun( $input, [@bibfiles], [@citations], $macro, $output );
    if ( $status ne 0 ) {
        return $status;
    }

    # and run the code
    return &{$code}();
}

# helper function to print usage information and exit
sub usageAndExit {
    my ($code) = @_;
    print STDERR
'bibtexmlr [--help] [--destination $DEST] [--cites $CITES] [--macro $MACRO] $COMPILED_BST [$BIBFILE [$BIBFILE ...]]'
      . "\n";
    return $code;
}

1;
