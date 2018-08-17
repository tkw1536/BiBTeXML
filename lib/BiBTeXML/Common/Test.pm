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

use Encode;
use Time::HiRes qw(time);

use File::Basename qw(dirname);
use File::Spec;

use base qw(Exporter);
our @EXPORT = (
  qw( &slurp &puts &isResult ),
  qw( &makeStringReader &makeFixtureReader ),
  qw( &measureBegin &measureEnd ),
);

# read an entire file into a string
sub slurp {
  my ($path) = @_;
  open my $fh, '<', $path or die "Can't open file $path: $!";
  my $file_content = do { local $/; binmode $fh; <$fh> };
  close($fh);
  $file_content =~ s/(?:\015\012|\015|\012)/\n/sg;
  return decode('utf-8', $file_content);
}

# write an entire file into a string
sub puts {
  my ($path, $content) = @_;
  open my $fh, '>', $path or die "Can't open file $path: $!";
  print $fh encode('utf-8', $content);
  close $fh;
}

# gets the path to a mock fixture
sub fixture {
  File::Spec->join(dirname(shift(@_)), 'fixtures', @_);
}

# makes a BiBTeXML::Common::StreamReader to a fixed string
sub makeStringReader {
  my ($content, $eat, $delimiter) = @_;
  my $reader = BiBTeXML::Common::StreamReader->new();
  $reader->openString(($eat ? ' ' : '') . $content . (defined($delimiter) ? $delimiter : ' '));
  $reader->eatChar if $eat;

  return $reader;
}

# makes a BiBTeXML::Common::StreamReader to a fixture
sub makeFixtureReader {
  my $reader = BiBTeXML::Common::StreamReader->new();
  my $path   = fixture(@_);
  $reader->openFile($path, "utf-8");
  return ($reader, $path);
}

# joins a list of objects by stringifying them
sub joinStrs {
  my @strs = map { $_->stringify; } @_;
  return join("\n\n", @strs);
}

# starts a measurement
sub measureBegin {
  return time;
}

# ends a measurement
sub measureEnd {
  my ($begin, $name) = @_;
  my $duration = time - $begin;
  Test::More::diag("evaluated $name in $duration seconds");
}

sub isResult {
  my ($results, $path, $message) = @_;
  Test::More::is(joinStrs(@{$results}), slurp("$path.txt"), $message);
}

1;
