use BiBTeXML::Common::Test;
use Test::More tests => 2;

subtest "requirements" => sub {
  plan tests => 2;

  use_ok("BiBTeXML::Common::StreamReader");
  use_ok("BiBTeXML::BibStyle");
};

doesParseFile("plain.bst");

sub doesParseFile {
  my ($name, $expectCommands) = @_;

  subtest $name => sub {
    plan tests => 1;

    my ($reader, $path) = makeFixtureReader(__FILE__, 'bstfiles', $name);

    # parse file and measure the time it takes
    my $begin = measureBegin;
    my ($results, $error) = readFile($reader);
    measureEnd($begin, $name);

    # check that we did not make any errors
    isResult($results, $path, "evaluates $name correctly");
  };
}

1;
