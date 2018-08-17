use Test::More tests => 6;

use File::Basename;
use File::Spec;

subtest "requirements" => sub {
  plan tests => 2;

  require_ok("BiBTeXML::Common::StreamReader");
  require_ok("BiBTeXML::Bibliography::BibParser");
};

subtest 'readLiteral' => sub {
  plan tests => 5;

  doesReadLiteral('empty', ',',           'BibString[LITERAL, "", from=1:1, to=1:1]');
  doesReadLiteral('space', 'hello world', 'BibString[LITERAL, "hello world", from=1:1, to=1:12]');
  doesReadLiteral('with an @ sign', 'hello@world', 'BibString[LITERAL, "hello@world", from=1:1, to=1:12]');
  doesReadLiteral('with an " sign', 'hello"world', 'BibString[LITERAL, "hello"world", from=1:1, to=1:12]');
  doesReadLiteral('surrounding space', 'hello  world     ', 'BibString[LITERAL, "hello  world", from=1:1, to=1:13]');

  sub doesReadLiteral {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input}");
    $reader->eatChar;

    # ensure that it actually
    my ($result) = BiBTeXML::Bibliography::BibParser::readLiteral($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readBrace' => sub {
  plan tests => 5;

  doesReadBrace('empty braces',  '{}',      'BibString[BRACKET, "", from=1:1, to=1:3]');
  doesReadBrace('simple braces', '{hello}', 'BibString[BRACKET, "hello", from=1:1, to=1:8]');
  doesReadBrace('nested braces', '{hello{world}}', 'BibString[BRACKET, "hello{world}", from=1:1, to=1:15]');
  doesReadBrace('brace with open \\', '{hello \{world}}', 'BibString[BRACKET, "hello \{world}", from=1:1, to=1:17]');
  doesReadBrace('brace with close \\', '{hello world\}}', 'BibString[BRACKET, "hello world\", from=1:1, to=1:15]');

  sub doesReadBrace {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BiBTeXML::Bibliography::BibParser::readBrace($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readQuote' => sub {
  plan tests => 4;

  doesReadQuote('empty quotes', '""',      'BibString[QUOTE, "", from=1:1, to=1:3]');
  doesReadQuote('simple quote', '"hello"', 'BibString[QUOTE, "hello", from=1:1, to=1:8]');
  doesReadQuote('with { s',     '"{\"}"',  'BibString[QUOTE, "{\"}", from=1:1, to=1:7]');
  doesReadQuote('quote with spaces', '"hello world"', 'BibString[QUOTE, "hello world", from=1:1, to=1:14]');

  sub doesReadQuote {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input ");
    $reader->eatChar;

    my ($result) = BiBTeXML::Bibliography::BibParser::readQuote($reader);
    ok($result->equals($expected), $name);

    $reader->finalize;
  }
};

subtest 'readTag' => sub {
  plan tests => 9;

  # value only
  doesReadTag('empty tag', '');
  doesReadTag('literal value', 'value', 'BibTag[name=, content=[BibString[LITERAL, "value", from=1:1, to=1:6]], from=1:1, to=1:6]');
  doesReadTag('quoted value', '"value"', 'BibTag[name=, content=[BibString[QUOTE, "value", from=1:1, to=1:8]], from=1:1, to=1:8]');
  doesReadTag('braced value', '{value}', 'BibTag[name=, content=[BibString[BRACKET, "value", from=1:1, to=1:8]], from=1:1, to=1:8]');
  doesReadTag('concated literals', 'value1 # value2', 'BibTag[name=, content=[BibString[LITERAL, "value1", from=1:1, to=1:7],BibString[LITERAL, "value2", from=1:10, to=1:16]], from=1:1, to=1:16]');
  doesReadTag('concated quote and literal', '"value1" # value2', 'BibTag[name=, content=[BibString[QUOTE, "value1", from=1:1, to=1:9],BibString[LITERAL, "value2", from=1:12, to=1:18]], from=1:1, to=1:18]');

  # name = value
  doesReadTag('simple name', 'name = value', 'BibTag[name=BibString[LITERAL, "name", from=1:1, to=1:5], content=[BibString[LITERAL, "value", from=1:8, to=1:13]], from=1:1, to=1:13]');
  doesReadTag('simple name (compact)', 'name=value', 'BibTag[name=BibString[LITERAL, "name", from=1:1, to=1:5], content=[BibString[LITERAL, "value", from=1:6, to=1:11]], from=1:1, to=1:11]');
  doesReadTag('name + concat value', 'name=a#"b"', 'BibTag[name=BibString[LITERAL, "name", from=1:1, to=1:5], content=[BibString[LITERAL, "a", from=1:6, to=1:7],BibString[QUOTE, "b", from=1:8, to=1:11]], from=1:1, to=1:11]');

  sub doesReadTag {
    my ($name, $input, $expected) = @_;

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString(" $input, ");    # the comma simulates the next value
    $reader->eatChar;

    my ($result) = BiBTeXML::Bibliography::BibParser::readTag($reader);

    if (defined($expected)) {
      ok($result->equals($expected), $name);
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

    my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'bibparser', $input);

    # create a new string reader with some dummy input
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openFile("$path.bib", 'utf-8');

    my ($result) = BiBTeXML::Bibliography::BibParser::readEntry($reader);
    ok($result->equals(slurp("$path.txt")), $input);
    $reader->finalize;
  }

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
};

1;
