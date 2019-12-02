use BiBTeXML::Common::Test;
use Test::More tests => 2;

my $base = fixture(__FILE__, "compiler", "");

sub doesCompileFile {
  my ($name) = @_;

  subtest $name => sub {
    plan tests => 2;

    # figure out the path
    my ($reader) = makeFixtureReader(__FILE__, 'bstfiles', $name);
    my $path = "${base}$name.txt";

    # read + parse the file
    my ($results, $error) = readFile($reader);
    diag($error) if $error;
    ok(!defined($error), "parses $name without error");

    # compile the parsed code
    my ($program, $perror) = compileProgram("BiBTeXML::Compiler::Target", $results, '');
    diag($perror) if $perror;
    # puts($path, $program); # to generate test cases
    is($program, slurp($path), "evaluates $name correctly");
  };
}

subtest "requirements" => sub {
  plan tests => 4;

  use_ok("BiBTeXML::Common::StreamReader");
  use_ok("BiBTeXML::BibStyle");
  use_ok("BiBTeXML::Compiler");
  use_ok("BiBTeXML::Compiler::Target");
};

doesCompileFile("plain.bst");

1;
