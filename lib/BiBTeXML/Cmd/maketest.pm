# /=====================================================================\ #
# |  BiBTeXML::Cmd::maketest                                            | #
# | maketest utility entry point                                        | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Cmd::maketest;
use strict;
use warnings;

use BiBTeXML::Common::Test qw(integrationTestPaths);
use BiBTeXML::Cmd::makebbl;
use BiBTeXML::Cmd::bibtexml;

sub main {
    # remove the first argument, and display help with a testname is missing
    shift(@_);
    return usageAndExit(1) if scalar(@_) ne 1;

    # figure out paths
    my ($bstIn, $bibfiles, $citesIn, $macroIn, $resultOut) = integrationTestPaths(shift(@_));

    # prepare makebbl args
    my @makebbl = ('--cites', join(',', @{$citesIn}), '--destination', $resultOut . '.org', $bstIn, @{$bibfiles});

    # run makebbl
    print STDERR "./tools/makebbl " . join(' ', @makebbl) . "\n";
    my $code = BiBTeXML::Cmd::makebbl->main(@makebbl);
    return $code unless $code eq 0;
    
    # prepare bibtexml args
    my @bibtexml = ('--wrap', '--cites', join(',', @{$citesIn}), '--destination', $resultOut, $bstIn, @{$bibfiles});
    push(@bibtexml, '--macro', $macroIn) if defined($macroIn);

    # run bibtexml
    print STDERR "./bin/bibtexml " . join(' ', @bibtexml) . "\n";
    return BiBTeXML::Cmd::bibtexml->main(@bibtexml);
}

# helper function to print usage information and exit
sub usageAndExit {
    my ($code) = @_;
    print STDERR 'maketest $NAME' . "\n";
    return $code;
}

1;
