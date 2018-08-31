use BiBTeXML::Common::Test;
use Test::More tests => 11;

subtest "requirements" => sub {
  plan tests => 1;

  use_ok("BiBTeXML::Runtime::Strings");
};

subtest "splitLetters" => sub {
  plan tests => 10;

  sub IsSplitLetters {
    my ($input, $expected) = @_;
    is_deeply([splitLetters($input)], $expected, $input);
  }

  IsSplitLetters('hello',   [['h', 'e',   'l', 'l', 'o'], [0, 0, 0, 0, 0]]);
  IsSplitLetters('h{e}llo', [['h', '{e}', 'l', 'l', 'o'], [0, 1, 0, 0, 0]]);

  IsSplitLetters('{hello} world', [['{h', 'e', 'l', 'l', 'o}', ' ', 'w', 'o', 'r', 'l', 'd'], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]]);
  IsSplitLetters('{{ab}c}d{{e}}', [['{{a', 'b}', 'c}', 'd', '{{e}}'], [2, 2, 1, 0, 2]]);
  IsSplitLetters('{{}}{a}', [['{{}}{a}'], [1]]);

  # un-balanced braces
  IsSplitLetters('}world', [['}w', 'o', 'r', 'l', 'd'], [0, 0, 0, 0, 0]]);

  # single accent
  IsSplitLetters('{\ae} world', [['{\ae}', ' ', 'w', 'o', 'r', 'l', 'd'], [0, 0, 0, 0, 0, 0, 0]]);

  # not-an-accent
  IsSplitLetters('{{\ae}} world', [['{{\\', 'a', 'e}}', ' ', 'w', 'o', 'r', 'l', 'd'], [2, 2, 2, 0, 0, 0, 0, 0, 0]]);

  # empty
  IsSplitLetters('{}', [['{}'], []]);

  # zero characters don't break stuff
  IsSplitLetters('{\0a}', [['{\0a}'], [0]]);
};

subtest "parseAccent" => sub {
  plan tests => 7;

  sub IsParseAccent {
    my ($input, $expected) = @_;
    is_deeply([parseAccent($input)], $expected, $input);
  }

  # not an accent
  IsParseAccent("{w", [0, '', '', "{w", '', '', undef, undef]);

  # well-known accents
  IsParseAccent("{\\ae}",   [1, '', '{\\',  'ae', '}',  '', 'ae', '']);
  IsParseAccent("{\\`a}",   [1, '', '{\\',  '`a', '}',  '', '`',  'a']);
  IsParseAccent("{\\`{a}}", [1, '', '{\`{', 'a',  '}}', '', '`',  'a']);

  # custom accents
  IsParseAccent("{\\ab}",            [1, '', '{\\',       'ab',     '}',  '', 'ab',    '']);
  IsParseAccent("{\\hello world}",   [1, '', '{\\hello ', 'world',  '}',  '', 'hello', 'world']);
  IsParseAccent("{\\hello{ thing}}", [1, '', '{\\hello{', ' thing', '}}', '', 'hello', ' thing']);
};

subtest "addPeriod" => sub {
  plan tests => 6;

  sub isAddPeriod {
    my ($input, $expected) = @_;
    is(addPeriod($input), $expected, $input);
  }

  isAddPeriod("",              "");
  isAddPeriod("}}",            "}}.");
  isAddPeriod("hello world!",  "hello world!");
  isAddPeriod("hello world",   "hello world.");
  isAddPeriod("hello world}",  "hello world}.");
  isAddPeriod("hello world!}", "hello world!}");
};

subtest "changeCase" => sub {
  plan tests => 12;

  sub isChangeCase {
    my ($input, $format, $expected) = @_;
    is(changeCase($input, $format), $expected, $format . ' => ' . $input);
  }

  # changing case of a single world
  isChangeCase("HeLlo", "u", "HELLO");
  isChangeCase("HeLlo", "l", "hello");
  isChangeCase("HeLlo", "t", "Hello");

  # case of something with brackets
  isChangeCase("HeLlo {WeIrD} world", "u", "HELLO {WeIrD} WORLD");
  isChangeCase("HeLlo {WeIrD} world", "l", "hello {WeIrD} world");
  isChangeCase("HeLlo {WeIrD} world", "t", "Hello {WeIrD} world");

  # nested brackets
  isChangeCase("a{b{c}}d", "u", "A{b{c}}D");

  # accents
  isChangeCase("{}{\\ae}",     "u", "{}{\\AE}");
  isChangeCase("{\\'a} world", "u", "{\\'A} WORLD");
  isChangeCase("{}{\\ss}",     "u", "{}SS");           # special case

  # not-an-accent
  isChangeCase("{\\0a} world", "u", "{\\0A} WORLD");

  # weird commands
  isChangeCase("{\\relax von}", "u", "{\\relax VON}");    # commands
};

subtest "getCase" => sub {
  plan tests => 11;

  sub isGetCase {
    my ($input, $expected) = @_;
    is_deeply(getCase($input), $expected, $input);
  }

  isGetCase('hello',       'l');
  isGetCase('',            'l');
  isGetCase('{\\`h}World', 'l');
  isGetCase('{\von}',      'l');

  isGetCase('{\relax von}', 'l');
  isGetCase('{\relax Von}', 'u');

  isGetCase('{von}',       'u');
  isGetCase('{-}hello',    'u');
  isGetCase('Hello',       'u');
  isGetCase('{-}Hello',    'u');
  isGetCase('{\\`H}world', 'u');
};

subtest "textLength" => sub {
  plan tests => 4;

  sub isTextLength {
    my ($input, $expected) = @_;
    is(textLength($input), $expected, $input);
  }

  isTextLength("a normal string",        15);
  isTextLength("a {normal} string",      15);
  isTextLength("a {no{r}mal} string",    15);
  isTextLength("a {\\o{normal}} string", 10);
};

subtest "textWidth" => sub {
  plan tests => 6;

  sub isTextWidth {
    my ($input, $expected) = @_;
    is(textWidth($input), $expected, $input);
  }

  isTextWidth("hello world",       4782);
  isTextWidth("thing",             2279);
  isTextWidth("{hello world}",     5782);
  isTextWidth("{\\ae}",            722);
  isTextWidth("{\\ab}",            0);
  isTextWidth("{\\example thing}", 2279);
};

subtest "textSubstring" => sub {
  plan tests => 4;

  sub isTextSubstring {
    my ($input, $start, $length, $expected) = @_;
    is(textSubstring($input, $start, $length), $expected, $input);
  }

  isTextSubstring("Charles",           1,  1, "C");
  isTextSubstring("{Ch}arles",         1,  1, "{");
  isTextSubstring("{\\relax Ch}arles", 1,  2, "{\\");
  isTextSubstring("B{\\`a}rt{\\`o}k",  -2, 3, "`o}");
};

subtest "textPrefix" => sub {
  plan tests => 3;

  sub isTextPrefix {
    my ($input, $length, $expected) = @_;
    is(textPrefix($input, $length), $expected, $input);
  }

  isTextPrefix("hello world",          2, "he");
  isTextPrefix("{{hello world}}",      2, "{{he}}");
  isTextPrefix("{\\accent world}1234", 2, "{\\accent world}1");
};

subtest "purify" => sub {
  plan tests => 9;

  sub IsTextPurify {
    my ($input, $expected) = @_;
    is(textPurify($input), $expected, $input);
  }

  # an example which encapsulates pretty much everything
  IsTextPurify('The {\relax stuff} and {\ae} things~-42', 'The stuff and ae things  42');

  # examples from Tame the BeaST, page 22
  IsTextPurify('t\^ete',     'tete');
  IsTextPurify('t{\^e}te',   'tete');
  IsTextPurify('t{\^{e}}te', 'tete');

  IsTextPurify('Bib{\TeX}', 'Bib');
  IsTextPurify('Bib\TeX',   'BibTeX');

  IsTextPurify('\OE', 'OE');

  IsTextPurify('The {\LaTeX} {C}ompanion',  'The  Companion');
  IsTextPurify('The { \LaTeX} {C}ompanion', 'The  LaTeX Companion');
};
