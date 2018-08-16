use Test::More tests => 5;

use File::Basename;
use File::Spec;

use Encode;
use Time::HiRes qw(time);

subtest "requirements" => sub {
  require_ok("BiBTeXML::Common::StreamReader");
  require_ok("BiBTeXML::Bibliography::BibParser");
};

doesParseFile("complicated.bib", 6);
doesEvalFile("complicated.bib");

doesParseFile("kwarc.bib", 6994);
doesEvalFile("kwarc.bib");

sub doesParseFile {
  my ($name, $expectEntries) = @_;

  subtest $name => sub {
    plan tests => 2;

    # create an input file
    my $reader = BiBTeXML::Common::StreamReader->new();
    my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'bibfiles', $name);
    $reader->openFile($path, "utf-8");

    # parse file and measure the time it takes
    my $start = time;
    my ($results, $errors) = BiBTeXML::Bibliography::BibParser::readFile($reader, 0);
    my $duration = time - $start;

    # check that we did not make any errors
    is(scalar(@$results), $expectEntries, 'parses correct number of entries from ' . $name);
    is(scalar(@$errors), 0, 'does not produce any errors parsing ' . $name);

    diag("parsed $name in $duration seconds");
  };
}

sub doesEvalFile {
  my ($name, $expectEntries) = @_;

  subtest $name => sub {
    plan tests => 2;

    # create an input file
    my $reader = BiBTeXML::Common::StreamReader->new();
    my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'bibfiles', $name);
    $reader->openFile($path, "utf-8");

    # parse file and measure the time
    my $start = time;
    my ($results, $errors) = BiBTeXML::Bibliography::BibParser::readFile($reader, 1);
    my $duration = time - $start;

    # check that we did not make any errors
    if (defined($expectEntries)) {
      is(scalar(@$results), $expectEntries, 'parses correct number of entries from ' . $name);
    } else {
      my @sresults = map { $_->stringify; } @{$results};
      my $resultstr = join("\n\n", @sresults);
      is($resultstr, slurp("$path.txt"), "evaluates $name correctly");
    }
    is(scalar(@$errors), 0, 'does not produce any errors parsing ' . $name);

    diag("evaluated $name in $duration seconds");
  };

  sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Can't open file $!";
    my $file_content = do { local $/; binmode $fh; <$fh> };
    close($fh);
    $file_content =~ s/(?:\015\012|\015|\012)/\n/sg;
    return decode('utf-8', $file_content);
  }

  sub puts {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Can't open file $!";
    print $fh encode('utf-8', $content);
    close $fh;
  }
}

1;
