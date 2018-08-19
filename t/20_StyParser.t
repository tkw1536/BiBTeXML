use BiBTeXML::Common::Test;
use Test::More tests => 7;

subtest "requirements" => sub {
  plan tests => 2;

  use_ok("BiBTeXML::Common::StreamReader");
  use_ok("BiBTeXML::BibStyle");
};

subtest 'readLiteral' => sub {
  plan tests => 4;

  doesReadLiteral('simple literal', 'hello#world', StyString('LITERAL', 'hello#world', [(1, 1, 1, 12)]));
  doesReadLiteral('ends after first space', 'hello world', StyString('LITERAL', 'hello', [(1, 1, 1, 6)]));
  doesReadLiteral('ends after }', 'hello}world', StyString('LITERAL', 'hello', [(1, 1, 1, 6)]));
  doesReadLiteral('ends after {', 'hello{world', StyString('LITERAL', 'hello', [(1, 1, 1, 6)]));

  sub doesReadLiteral {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1);
    my ($result) = BiBTeXML::BibStyle::StyParser::readLiteral($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readNumber' => sub {
  plan tests => 5;

  doesReadNumber('simple number',          '#0',        StyString('NUMBER', 0,      [(1, 1, 1, 3)]));
  doesReadNumber('positive number',        '#+1',       StyString('NUMBER', 1,      [(1, 1, 1, 4)]));
  doesReadNumber('negative number',        '#-1',       StyString('NUMBER', -1,     [(1, 1, 1, 4)]));
  doesReadNumber('ends after first space', '#123456 ',  StyString('NUMBER', 123456, [(1, 1, 1, 8)]));
  doesReadNumber('ends after }',           '#123456}7', StyString('NUMBER', 123456, [(1, 1, 1, 8)]));

  sub doesReadNumber {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1);
    my ($result) = BiBTeXML::BibStyle::StyParser::readNumber($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readReference' => sub {
  plan tests => 3;

  doesReadReference('simple reference', '\'hello@world', StyString('REFERENCE', 'hello@world', [(1, 1, 1, 13)]));
  doesReadReference('ends after first space', "'hello world", StyString('REFERENCE', 'hello', [(1, 1, 1, 7)]));
  doesReadReference('ends with }', "'hello}world", StyString('REFERENCE', 'hello', [(1, 1, 1, 7)]));

  sub doesReadReference {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1);
    my ($result) = BiBTeXML::BibStyle::StyParser::readReference($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readQuote' => sub {
  plan tests => 4;

  doesReadQuote('empty quotes', '""',      StyString('QUOTE', '',      [(1, 1, 1, 3)]));
  doesReadQuote('simple quote', '"hello"', StyString('QUOTE', 'hello', [(1, 1, 1, 8)]));
  doesReadQuote('no escapes',   '"{\"}"',  StyString('QUOTE', '{\\',   [(1, 1, 1, 5)]));
  doesReadQuote('quote with spaces', '"hello world"', StyString('QUOTE', 'hello world', [(1, 1, 1, 14)]));

  sub doesReadQuote {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1);
    my ($result) = BiBTeXML::BibStyle::StyParser::readQuote($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readBlock' => sub {
  plan tests => 4;

  doesReadBlock('empty block', '{}', StyString('BLOCK', [], [(1, 1, 1, 3)]));
  doesReadBlock('block of literal', '{hello}', StyString('BLOCK', [StyString('LITERAL', 'hello', [(1, 2, 1, 7)])], [(1, 1, 1, 8)]));
  doesReadBlock('block of multiples', '{hello \'world #3}', StyString('BLOCK', [StyString('LITERAL', 'hello', [(1, 2, 1, 7)]), StyString('REFERENCE', 'world', [(1, 8, 1, 14)]), StyString('NUMBER', 3, [(1, 15, 1, 17)])], [(1, 1, 1, 18)]));
  doesReadBlock('nested blocks', '{outer {inner #1} outer}', StyString('BLOCK', [StyString('LITERAL', 'outer', [(1, 2, 1, 7)]), StyString('BLOCK', [StyString('LITERAL', 'inner', [(1, 9, 1, 14)]), StyString('NUMBER', 1, [(1, 15, 1, 17)])], [(1, 8, 1, 18)]), StyString('LITERAL', 'outer', [(1, 19, 1, 24)])], [(1, 1, 1, 25)]));

  sub doesReadBlock {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1);
    my ($result, $e) = BiBTeXML::BibStyle::StyParser::readBlock($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readCommand' => sub {
  plan tests => 10;

  doesReadCommand('ENTRY', 'ENTRY    {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'ENTRY', [(1, 1, 1, 6)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]), StyString('BLOCK', [StyString('LITERAL', 'b', [(1, 15, 1, 16)])], [(1, 14, 1, 17)]), StyString('BLOCK', [StyString('LITERAL', 'c', [(1, 19, 1, 20)])], [(1, 18, 1, 21)]))], [(1, 1, 1, 21)]));
  doesReadCommand('EXECUTE', 'EXECUTE  {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'EXECUTE', [(1, 1, 1, 8)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]))], [(1, 1, 1, 13)]));
  doesReadCommand('FUNCTION', 'FUNCTION {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'FUNCTION', [(1, 1, 1, 9)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]), StyString('BLOCK', [StyString('LITERAL', 'b', [(1, 15, 1, 16)])], [(1, 14, 1, 17)]))], [(1, 1, 1, 17)]));
  doesReadCommand('INTEGERS', 'INTEGERS {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'INTEGERS', [(1, 1, 1, 9)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]))], [(1, 1, 1, 13)]));
  doesReadCommand('ITERATE', 'ITERATE  {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'ITERATE', [(1, 1, 1, 8)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]))], [(1, 1, 1, 13)]));
  doesReadCommand('MACRO', 'MACRO    {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'MACRO', [(1, 1, 1, 6)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]), StyString('BLOCK', [StyString('LITERAL', 'b', [(1, 15, 1, 16)])], [(1, 14, 1, 17)]))], [(1, 1, 1, 17)]));
  doesReadCommand('READ', 'READ     {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'READ', [(1, 1, 1, 5)]), [()], [(1, 1, 1, 5)]));
  doesReadCommand('REVERSE', 'REVERSE  {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'REVERSE', [(1, 1, 1, 8)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]))], [(1, 1, 1, 13)]));
  doesReadCommand('SORT', 'SORT     {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'SORT', [(1, 1, 1, 5)]), [()], [(1, 1, 1, 5)]));
  doesReadCommand('STRINGS', 'STRINGS  {a} {b} {c} {d}', StyCommand(StyString('LITERAL', 'STRINGS', [(1, 1, 1, 8)]), [(StyString('BLOCK', [StyString('LITERAL', 'a', [(1, 11, 1, 12)])], [(1, 10, 1, 13)]))], [(1, 1, 1, 13)]));

  sub doesReadCommand {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1);
    my ($result) = BiBTeXML::BibStyle::StyParser::readCommand($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

1;
