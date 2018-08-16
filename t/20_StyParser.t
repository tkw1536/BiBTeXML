use Test::More tests => 5;

use File::Basename;
use File::Spec;

# we should be able to read the module
require_ok("BibTeXML::Common::StreamReader");
require_ok("BibTeXML::BibStyle::StyParser");

subtest 'readLiteral' => sub {
  plan tests => 2;

  doesReadLiteral('simple literal', 'hello#world', 'StyString[LITERAL, "hello#world", from=1:1, to=1:12]');
  doesReadLiteral('ends after first space', 'hello world', 'StyString[LITERAL, "hello", from=1:1, to=1:6]');

  sub doesReadLiteral {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BibTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BibTeXML::BibStyle::StyParser::readLiteral($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readArgument' => sub {
  plan tests => 2;

  doesReadArgument('simple argument', '#0', 'StyString[ARGUMENT, 0, from=1:1, to=1:3]');
  doesReadArgument('ends after first space', '#123456 ', 'StyString[ARGUMENT, 123456, from=1:1, to=1:8]');

  sub doesReadArgument {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BibTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BibTeXML::BibStyle::StyParser::readArgument($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readQuote' => sub {
  plan tests => 4;

  doesReadQuote('empty quotes', '""',      'StyString[QUOTE, "", from=1:1, to=1:3]');
  doesReadQuote('simple quote', '"hello"', 'StyString[QUOTE, "hello", from=1:1, to=1:8]');
  doesReadQuote('with { s',     '"{\"}"',  'StyString[QUOTE, "{\"}", from=1:1, to=1:7]');
  doesReadQuote('quote with spaces', '"hello world"', 'StyString[QUOTE, "hello world", from=1:1, to=1:14]');

  sub doesReadQuote {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BibTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BibTeXML::BibStyle::StyParser::readQuote($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

1;
