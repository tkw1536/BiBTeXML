use Test::More tests => 2;

use File::Basename;
use File::Spec;

use Encode;
use Time::HiRes qw(time);

subtest "requirements" => sub {
  require_ok("BiBTeXML::Common::StreamReader");
  require_ok("BiBTeXML::BibStyle::StyParser");
};

doesParseFile("plain.bst");

sub doesParseFile {
  my ($name, $expectCommands) = @_;

  subtest $name => sub {
    plan tests => 1;

    # create an input file
    my $reader = BiBTeXML::Common::StreamReader->new();
    my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'bstfiles', $name);
    $reader->openFile($path, "utf-8");

    # parse file and measure the time it takes
    my $start = time;
    my ($result, $error) = BiBTeXML::BibStyle::StyParser::readFile($reader);
    my $duration = time - $start;

    # check that we did not make any errors
    my @sresults = map { $_->stringify; } @{$result};
    my $resultstr = join("\n\n", @sresults);
    is($resultstr, slurp("$path.txt"), "evaluates $name correctly");

    diag("parsed $name in $duration seconds");
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
