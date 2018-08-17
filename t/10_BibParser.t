use BiBTeXML::Common::Test;
use Test::More tests => 6;

subtest "requirements" => sub {
  plan tests => 4;

  use_ok("BiBTeXML::Common::StreamReader");
  use_ok("BiBTeXML::Bibliography::BibParser");

  use_ok("BiBTeXML::Bibliography::BibString");
  use_ok("BiBTeXML::Bibliography::BibTag");
};

subtest 'readLiteral' => sub {
  plan tests => 5;

  doesReadLiteral('empty', ',',           BibString('LITERAL', '',            [(1, 1, 1, 1)]));
  doesReadLiteral('space', 'hello world', BibString('LITERAL', 'hello world', [(1, 1, 1, 12)]));
  doesReadLiteral('with an @ sign', 'hello@world', BibString('LITERAL', 'hello@world', [(1, 1, 1, 12)]));
  doesReadLiteral('with an " sign', 'hello"world', BibString('LITERAL', 'hello"world', [(1, 1, 1, 12)]));
  doesReadLiteral('surrounding space', 'hello  world     ', BibString('LITERAL', 'hello  world', [(1, 1, 1, 13)]));

  sub doesReadLiteral {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1, '}');
    my ($result) = BiBTeXML::Bibliography::BibParser::readLiteral($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readBrace' => sub {
  plan tests => 5;

  doesReadBrace('empty braces',  '{}',      BibString('BRACKET', '',      [(1, 1, 1, 3)]));
  doesReadBrace('simple braces', '{hello}', BibString('BRACKET', 'hello', [(1, 1, 1, 8)]));
  doesReadBrace('nested braces', '{hello{world}}', BibString('BRACKET', 'hello{world}', [(1, 1, 1, 15)]));
  doesReadBrace('brace with open \\', '{hello \{world}}', BibString('BRACKET', 'hello \\{world}', [(1, 1, 1, 17)]));
  doesReadBrace('brace with close \\', '{hello world\}}', BibString('BRACKET', 'hello world\\', [(1, 1, 1, 15)]));

  sub doesReadBrace {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = makeStringReader($input, 1);
    my ($result) = BiBTeXML::Bibliography::BibParser::readBrace($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readQuote' => sub {
  plan tests => 4;

  doesReadQuote('empty quotes', '""',      BibString('QUOTE', '',      [(1, 1, 1, 3)]));
  doesReadQuote('simple quote', '"hello"', BibString('QUOTE', 'hello', [(1, 1, 1, 8)]));
  doesReadQuote('with { s',     '"{\"}"',  BibString('QUOTE', '{\\"}', [(1, 1, 1, 7)]));
  doesReadQuote('quote with spaces', '"hello world"', BibString('QUOTE', 'hello world', [(1, 1, 1, 14)]));

  sub doesReadQuote {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1, ', ');
    my ($result) = BiBTeXML::Bibliography::BibParser::readQuote($reader);

    is_deeply($result, $expected, $name);

    $reader->finalize;
  }
};

subtest 'readTag' => sub {
  plan tests => 9;

  # value only
  doesReadTag('empty tag', '', undef);
  doesReadTag('literal value', 'value', BibTag(undef, [(BibString('LITERAL', 'value', [(1, 1, 1, 6)]))], [(1, 1, 1, 6)]));
  doesReadTag('quoted value', '"value"', BibTag(undef, [(BibString('QUOTE', 'value', [(1, 1, 1, 8)]))], [(1, 1, 1, 8)]));
  doesReadTag('braced value', '{value}', BibTag(undef, [(BibString('BRACKET', 'value', [(1, 1, 1, 8)]))], [(1, 1, 1, 8)]));
  doesReadTag('concated literals', 'value1 # value2', BibTag(undef, [(BibString('LITERAL', 'value1', [(1, 1, 1, 7)]), BibString('LITERAL', 'value2', [(1, 10, 1, 16)]))], [(1, 1, 1, 16)]));
  doesReadTag('concated quote and literal', '"value1" # value2', BibTag(undef, [(BibString('QUOTE', 'value1', [(1, 1, 1, 9)]), BibString('LITERAL', 'value2', [(1, 12, 1, 18)]))], [(1, 1, 1, 18)]));

  # name = value
  doesReadTag('simple name', 'name = value', BibTag(BibString('LITERAL', 'name', [(1, 1, 1, 5)]), [(BibString('LITERAL', 'value', [(1, 8, 1, 13)]))], [(1, 1, 1, 13)]));
  doesReadTag('simple name (compact)', 'name=value', BibTag(BibString('LITERAL', 'name', [(1, 1, 1, 5)]), [(BibString('LITERAL', 'value', [(1, 6, 1, 11)]))], [(1, 1, 1, 11)]));
  doesReadTag('name + concat value', 'name=a#"b"', BibTag(BibString('LITERAL', 'name', [(1, 1, 1, 5)]), [(BibString('LITERAL', 'a', [(1, 6, 1, 7)]), BibString('QUOTE', 'b', [(1, 8, 1, 11)]))], [(1, 1, 1, 11)]));

  sub doesReadTag {
    my ($name, $input, $expected) = @_;

    my $reader = makeStringReader($input, 1, ', ');
    my ($result) = BiBTeXML::Bibliography::BibParser::readTag($reader);

    if (defined($expected)) {
      is_deeply($result, $expected, $name);
    } else {
      ok(!defined($result), $name);
    }

    $reader->finalize;
  }
};

use Encode;

subtest 'readEntry' => sub {
  plan tests => 3;

  doesReadEntry('01_preamble');
  doesReadEntry('02_string');
  doesReadEntry('03_article');

  sub doesReadEntry {
    my ($input, $expected) = @_;

    # create a new string reader with some dummy input
    my ($reader, $path) = makeFixtureReader(__FILE__, 'bibparser', "$input.bib");

    my ($result) = BiBTeXML::Bibliography::BibParser::readEntry($reader);
    is($result->stringify, slurp("$path.txt"), $input);
    $reader->finalize;
  }
};

1;
