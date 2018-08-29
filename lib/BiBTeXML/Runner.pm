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

use BiBTeXML::Runtime::Config;
use BiBTeXML::Common::StreamReader;

use base qw(Exporter);
our @EXPORT = qw(
  &createRun
);

# returns a sub that can be called to execute a given input file
# and known output files
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
  my ($input, $bibfiles, $output) = @_;

  # open input file
  my $cfh;
  open $cfh, '<', $input;
  unless (defined($cfh)) {
    print STDERR "Unable to find compiled bstfile $input";
    return 2, undef;
  }

  # read code
  my $code = do { local $/; binmode $cfh; <$cfh> };
  close($cfh);
  $code = decode('utf-8', $code);

  # WARNING
  $code = eval $code;
  unless (defined($code)) {
    print STDERR $@;
    return 3;
  }

  # check that all input files exist
  my $bf;
  foreach $bf (@$bibfiles) {
    unless (-e $bf) {
      print STDERR "Unable to find bibfile $bf";
      return 4, undef;
    }
  }

  # create readers for all of them
  my $reader;
  my @readers = ();
  foreach $bf (@$bibfiles) {
    $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openFile($bf);
    push(@readers, $bf, $reader);
  }

  # create an output file
  my $ofh;
  if (defined($ofh)) {
    open($ofh, ">", $output);
  } else {
    $ofh = *STDOUT;
  }
  unless (defined($ofh)) {
    print STDERR "Unable to fine $output";
    return 5, undef;
  }

  # create a configuration
  # TODO: Allow interception of sources
  my $config = BiBTeXML::Runtime::Config->new(undef, sub {
      my ($string, $source) = @_;
      print $ofh $string;
    }, sub {
      my ($level, $message, $source) = @_;
      print STDERR "[$level] $message\n";
    }, []);

  # and get the context
  my $context = $config->getContext;

  # return the magic code to be run
  return 0, sub {
    my $exitcode = 6;
    eval {
      &{$code}($context, $config);
      $exitcode = 0;
    };
    print STDERR $@ if defined($@);
    close($ofh);
    return $exitcode;
  };

}
