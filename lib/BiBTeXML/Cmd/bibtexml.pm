# /=====================================================================\ #
# |  BiBTeXML::Cmd::bibtexml                                            | #
# | bibtexml entry point                                                | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Cmd::bibtexml;
use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);

use BiBTeXML::Runner;
use BiBTeXML::Common::Utils qw(slurp);

sub main {
    shift(@_);    # remove the first argument

    my ( $output, $macro, $cites, $wrap, $help ) = ( undef, undef, '*', 0, 0 );
    GetOptionsFromArray(
        \@_,
        "destination=s" => \$output,
        "macro=s"       => \$macro,
        "cites=s"       => \$cites,
        "wrap"          => \$wrap,
        "help"          => \$help,
    ) or return usageAndExit(1);

    # if we requested help, or we had a wrong number of arguments, exit
    return usageAndExit(0) if ($help);
    return usageAndExit(1) if scalar(@_) le 1;

    # check that the bst file exists
    my ( $bstfile, @bibfiles ) = @_;
    unless ( -e $bstfile ) {
        print STDERR "Unable to find bstfile $bstfile\n";
        return 3;
    }

    # create a reader for it
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openFile($bstfile);

    # compile the bst file
    my ( $code, $compiled ) = createCompile(
        'Perl', $reader,
        sub {
            print STDERR @_;
        },
        $bstfile
    );
    return $code, undef if $code ne 0;

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
        $wrap,
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
'bibtexml [--help] [--wrap] [--destination $DEST] [--cites $CITES] [--macro $MACRO] $BSTFILE $BIBFILE [$BIBFILE ...]'
      . "\n";
    return $code;
}

1;
