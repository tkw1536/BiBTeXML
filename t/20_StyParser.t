use Test::More tests => 8;

use File::Basename;
use File::Spec;

# we should be able to read the module
require_ok("BiBTeXML::Common::StreamReader");
require_ok("BiBTeXML::BibStyle::StyParser");

subtest 'readLiteral' => sub {
  plan tests => 4;

  doesReadLiteral('simple literal', 'hello#world', 'StyString[LITERAL, "hello#world", from=1:1, to=1:12]');
  doesReadLiteral('ends after first space', 'hello world', 'StyString[LITERAL, "hello", from=1:1, to=1:6]');
  doesReadLiteral('ends after }', 'hello}world', 'StyString[LITERAL, "hello", from=1:1, to=1:6]');
  doesReadLiteral('ends after {', 'hello{world', 'StyString[LITERAL, "hello", from=1:1, to=1:6]');

  sub doesReadLiteral {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BiBTeXML::BibStyle::StyParser::readLiteral($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readNumber' => sub {
  plan tests => 3;

  doesReadNumber('simple number', '#0', 'StyString[NUMBER, 0, from=1:1, to=1:3]');
  doesReadNumber('ends after first space', '#123456 ', 'StyString[NUMBER, 123456, from=1:1, to=1:8]');
  doesReadNumber('ends after }', '#123456}7', 'StyString[NUMBER, 123456, from=1:1, to=1:8]');

  sub doesReadNumber {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BiBTeXML::BibStyle::StyParser::readNumber($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readReference' => sub {
  plan tests => 3;

  doesReadReference('simple reference', '\'hello@world', 'StyString[REFERENCE, "hello@world", from=1:1, to=1:13]');
  doesReadReference('ends after first space', "'hello world", 'StyString[REFERENCE, "hello", from=1:1, to=1:7]');
  doesReadReference('ends with }', "'hello}world", 'StyString[REFERENCE, "hello", from=1:1, to=1:7]');

  sub doesReadReference {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result, $e) = BiBTeXML::BibStyle::StyParser::readReference($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readQuote' => sub {
  plan tests => 4;

  doesReadQuote('empty quotes', '""',      'StyString[QUOTE, "", from=1:1, to=1:3]');
  doesReadQuote('simple quote', '"hello"', 'StyString[QUOTE, "hello", from=1:1, to=1:8]');
  doesReadQuote('no escapes',   '"{\"}"',  'StyString[QUOTE, "{\", from=1:1, to=1:5]');
  doesReadQuote('quote with spaces', '"hello world"', 'StyString[QUOTE, "hello world", from=1:1, to=1:14]');

  sub doesReadQuote {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BiBTeXML::BibStyle::StyParser::readQuote($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readBlock' => sub {
  plan tests => 4;

  doesReadBlock('empty block', '{}', 'StyString[BLOCK, [], from=1:1, to=1:3]');
  doesReadBlock('block of literal', '{hello}', 'StyString[BLOCK, [StyString[LITERAL, "hello", from=1:2, to=1:7]], from=1:1, to=1:8]');
  doesReadBlock('block of multiples', '{hello \'world #3}', 'StyString[BLOCK, [StyString[LITERAL, "hello", from=1:2, to=1:7], StyString[REFERENCE, "world", from=1:8, to=1:14], StyString[NUMBER, 3, from=1:15, to=1:17]], from=1:1, to=1:18]');
  doesReadBlock('nested blocks', '{outer {inner #1} outer}', 'StyString[BLOCK, [StyString[LITERAL, "outer", from=1:2, to=1:7], StyString[BLOCK, [StyString[LITERAL, "inner", from=1:9, to=1:14], StyString[NUMBER, 1, from=1:15, to=1:17]], from=1:8, to=1:18], StyString[LITERAL, "outer", from=1:19, to=1:24]], from=1:1, to=1:25]');

  sub doesReadBlock {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result, $e) = BiBTeXML::BibStyle::StyParser::readBlock($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readCommand' => sub {
  plan tests => 10;

  doesReadCommand('ENTRY',    'ENTRY    {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "ENTRY", from=1:1, to=1:6], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13], StyString[BLOCK, [StyString[LITERAL, "b", from=1:15, to=1:16]], from=1:14, to=1:17], StyString[BLOCK, [StyString[LITERAL, "c", from=1:19, to=1:20]], from=1:18, to=1:21]], from=1:1, to=1:21]');
  doesReadCommand('EXECUTE',  'EXECUTE  {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "EXECUTE", from=1:1, to=1:8], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13]], from=1:1, to=1:13]');
  doesReadCommand('FUNCTION', 'FUNCTION {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "FUNCTION", from=1:1, to=1:9], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13], StyString[BLOCK, [StyString[LITERAL, "b", from=1:15, to=1:16]], from=1:14, to=1:17]], from=1:1, to=1:17]');
  doesReadCommand('INTEGERS', 'INTEGERS {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "INTEGERS", from=1:1, to=1:9], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13]], from=1:1, to=1:13]');
  doesReadCommand('ITERATE',  'ITERATE  {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "ITERATE", from=1:1, to=1:8], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13]], from=1:1, to=1:13]');
  doesReadCommand('MACRO',    'MACRO    {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "MACRO", from=1:1, to=1:6], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13], StyString[BLOCK, [StyString[LITERAL, "b", from=1:15, to=1:16]], from=1:14, to=1:17]], from=1:1, to=1:17]');
  doesReadCommand('READ',     'READ     {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "READ", from=1:1, to=1:5], [], from=1:1, to=1:5]');
  doesReadCommand('REVERSE',  'REVERSE  {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "REVERSE", from=1:1, to=1:8], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13]], from=1:1, to=1:13]');
  doesReadCommand('SORT',     'SORT     {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "SORT", from=1:1, to=1:5], [], from=1:1, to=1:5]');
  doesReadCommand('STRINGS',  'STRINGS  {a} {b} {c} {d}', 'StyCommand[StyString[LITERAL, "STRINGS", from=1:1, to=1:8], [StyString[BLOCK, [StyString[LITERAL, "a", from=1:11, to=1:12]], from=1:10, to=1:13]], from=1:1, to=1:13]');


  sub doesReadCommand {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result, $e) = BiBTeXML::BibStyle::StyParser::readCommand($reader);
    diag(defined($result) ? $result->stringify : $e) unless $result->equals($expected);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

1;
