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

use Getopt::Long qw(GetOptionsFromArray);

use BiBTeXML::Runner;
use BiBTeXML::Common::Utils qw(slurp);

sub main {
    shift(@_);    # remove the first argument

    my ( $output, $macro, $cites, $wrapped, $help ) =
      ( undef, undef, "*", 0, 0 );
    GetOptionsFromArray(
        \@_,
        "destination=s" => \$output,
        "macro=s"       => \$macro,
        "cites=s"       => \$cites,
        "wrap"          => \$wrapped,
        "help"          => \$help,
    ) or return usageAndExit(1);

    # if we requested help, or we had a wrong number of arguments, exit
    return usageAndExit(0) if ($help);
    return usageAndExit(1) if scalar(@_) eq 0;

    # parse arguments
    my ( $input, @bibfiles ) = @_;

    # read the the compiled code
    my $compiled = slurp($input);

    # create a run
    my @citations = split( /,/, $cites );
    my ( $status, $runcode ) = createRun(
        $compiled,
        [@bibfiles],
        [@citations],
        $macro,
        sub {
            print STDERR @_;
        },
        $output,
        $wrapped,
    );
    if ( $status ne 0 ) {
        return $status;
    }

    # and run the code
    return &{$runcode}();
}

# helper function to print usage information and exit
sub usageAndExit {
    my ($code) = @_;
    print STDERR
'bibtexmlr [--help] [--wrap] [--destination $DEST] [--cites $CITES] [--macro $MACRO] $COMPILED_BST $BIBFILE [$BIBFILE ...]'
      . "\n";
    return $code;
}

1;
