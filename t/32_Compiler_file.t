use BiBTeXML::Common::Test;
use Test::More tests => 2;

subtest "requirements" => sub {
  plan tests => 3;

  use_ok("BiBTeXML::Common::StreamReader");
  use_ok("BiBTeXML::BibStyle");
  use_ok("BiBTeXML::Compiler");
};

doesCompileFile("plain.bst");

sub doesCompileFile {
  my ($name, $expectCommands) = @_;

  subtest $name => sub {
    plan tests => 2;

    # parse commands in the file
    my ($reader, $path) = makeFixtureReader(__FILE__, 'bstfiles', $name);
    my ($results, $error) = readFile($reader);

    ok(!defined($error), "parses $name without error");

    # compile them
    my ($program, $perror) = compileProgram($results);
    is($program, slurp("$path.txt.compiled"), "evaluates $name correctly");
  };
}

1;
