use BiBTeXML::Common::Test;
use Test::More tests => 10;

subtest "requirements" => sub {
  plan tests => 1;

  use_ok("BiBTeXML::Runtime::Utils");
};

subtest "addPeriod" => sub {
  plan tests => 5;

  sub isAddPeriod {
    my ($input, $expected) = @_;
    is(addPeriod($input), $expected, $input);
  }

  isAddPeriod("}}",            "}}.");
  isAddPeriod("hello world!",  "hello world!");
  isAddPeriod("hello world",   "hello world.");
  isAddPeriod("hello world}",  "hello world}.");
  isAddPeriod("hello world!}", "hello world!}");
};

subtest "changeAccent" => sub {
  plan tests => 6;

  sub isChangeAccent {
    my ($input, $format, $expected) = @_;
    is(changeAccent($input, $format), $expected, $format . ' => ' . $input);
  }

  isChangeAccent("ab",           "u", "AB");
  isChangeAccent("'a",           "u", "'A");
  isChangeAccent("`a",           "u", "`A");
  isChangeAccent("a0",           "u", "a0");
  isChangeAccent("hello{world}", "u", "hello{WORLD}");
  isChangeAccent("hello",        "u", "hello");
};

subtest "changeCase" => sub {
  plan tests => 10;

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
  isChangeCase("{\\'a} world", "u", "{\\'A} WORLD");
  isChangeCase("{\\0a} world", "u", "{\\0a} WORLD");    #not an accent

  # weird commands
  isChangeCase("{\\relax von}", "u", "{\\relax VON}");    # commands
};

subtest "splitNames" => sub {
  plan tests => 7;

  sub isSplitNames {
    my ($input, $expected) = @_;
    is_deeply([splitNames($input)], $expected, $input);
  }

  isSplitNames("tom and jerry", ["tom", "jerry"]);
  isSplitNames("and jerry", ["and jerry"]);
  isSplitNames("tom { and { and } } jerry",           ["tom { and { and } } jerry"]);
  isSplitNames("jerry and",                           ["jerry and"]);
  isSplitNames("tom cat and jerry mouse",             ["tom cat", "jerry mouse"]);
  isSplitNames("tom cat and jerry mouse and nibbles", ["tom cat", "jerry mouse", "nibbles"]);
  isSplitNames("tom cat and jerry mouse and nibbles { and } Uncle Pecos", ["tom cat", "jerry mouse", "nibbles { and } Uncle Pecos"]);
};

subtest "numNames" => sub {
  plan tests => 7;

  sub isNumNames {
    my ($input, $expected) = @_;
    is(numNames($input), $expected, $input);
  }

  isNumNames("tom and jerry",                                           2);
  isNumNames("and jerry",                                               1);
  isNumNames("tom { and { and } } jerry",                               1);
  isNumNames("jerry and",                                               1);
  isNumNames("tom cat and jerry mouse",                                 2);
  isNumNames("tom cat and jerry mouse and nibbles",                     3);
  isNumNames("tom cat and jerry mouse and nibbles { and } Uncle Pecos", 3);
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

subtest "splitNameWords" => sub {
  plan tests => 9;

  sub isSplitNameWords {
    my ($input, $expected) = @_;
    is_deeply([splitNameWords($input)], $expected, $input);
  }

  isSplitNameWords('Catherine Crook de Camp', [['Catherine ', 'Crook ', 'de ', 'Camp'], [], []]);
  isSplitNameWords('{-}ky Jean Claude', [['{-}ky ', 'Jean ', 'Claude'], [], []]);
  isSplitNameWords('ky{-} Jean Claude', [['ky{-} ', 'Jean ', 'Claude'], [], []]);
  isSplitNameWords('ky {-} Jean Claude', [['ky ', '{-} ', 'Jean ', 'Claude'], [], []]);

  isSplitNameWords('Claude, Jon', [['Claude'], ['Jon'], []]);
  isSplitNameWords('Claude the , Jon e', [['Claude ', 'the '], ['Jon ', 'e'], []]);
  isSplitNameWords('the, jr, thing', [['the'], ['jr'], ['thing']]);

  isSplitNameWords('Jean-Claude Van Damme', [['Jean-', 'Claude ', 'Van ', 'Damme'], [], []]);
  isSplitNameWords('Jean{-}Claude Van Damme', [['Jean{-}Claude ', 'Van ', 'Damme'], [], []]);
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

subtest "splitNameParts" => sub {
  plan tests => 11;

  sub isSplitNameParts {
    my ($input, $expected) = @_;
    is_deeply([splitNameParts($input)], $expected, $input);
  }

  # 'simple' cases
  isSplitNameParts('Catherine Crook de Camp', [['Catherine ', 'Crook '], ['de '], [], ['Camp']]);
  isSplitNameParts('{-}ky', [[], [], [], ['{-}ky']]);
  isSplitNameParts('jean de la fontaine du bois joli', [[], ['jean ', 'de ', 'la ', 'fontaine ', 'du ', 'bois '], [], ['joli']]);
  isSplitNameParts('Alfred Elton {van} Vogt', [['Alfred ', 'Elton ', '{van} '], [], [], ['Vogt']]);
  isSplitNameParts('Alfred Elton {\relax van} Vogt', [['Alfred ', 'Elton '], ['{\relax van} '], [], ['Vogt']]);
  isSplitNameParts('Alfred Elton {\relax Van} Vogt', [['Alfred ', 'Elton ', '{\relax Van} '], [], [], ['Vogt']]);
  isSplitNameParts('Michael {Marshall Smith}', [['Michael '], [], [], ['{Marshall Smith}']]);

  # 'hypenated' cases
  isSplitNameParts('Jean-Claude {Smit-le-B{\`e}n{\`e}dicte}', [['Jean-', 'Claude '], [], [], ['{Smit-le-B{\`e}n{\`e}dicte}']]);
  isSplitNameParts('Jean-Claude {Smit-le-B{\`e}n{\`e}dicte}', [['Jean-', 'Claude '], [], [], ['{Smit-le-B{\`e}n{\`e}dicte}']]);
  isSplitNameParts('Kenneth~Robeson', [['Kenneth~'], [], [], ['Robeson']]);
  isSplitNameParts('Louis-Albert', [[], [], [], ['Louis-Albert']]);

};
