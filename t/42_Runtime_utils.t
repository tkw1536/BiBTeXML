use BiBTeXML::Common::Test;
use Test::More tests => 15;

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

subtest "abbrevName" => sub {
  plan tests => 4;

  sub isAbbrevName {
    my ($input, $expected) = @_;
    is(abbrevName($input), $expected, $input);
  }

  isAbbrevName("Charles",           "C");
  isAbbrevName("{Ch}arles",         "C");
  isAbbrevName("{\\relax Ch}arles", "{\\relax Ch}");
  isAbbrevName("{-}ky",             "k");
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

subtest "splitNameWords" => sub {
  plan tests => 13;

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

  # from Names in BibTEX and MlBibTEX, page 245
  isSplitNameWords('Edgar  Rice', [['Edgar ', 'Rice'],  [], []]);
  isSplitNameWords('Edgar ~Rice', [['Edgar ', 'Rice'],  [], []]);
  isSplitNameWords('Edgar~ Rice', [['Edgar~', 'Rice'],  [], []]);
  isSplitNameWords('Karl- Heinz', [['Karl-',  'Heinz'], [], []]);
};

subtest "splitNameParts" => sub {
  plan tests => 12;

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

  #
  isSplitNameParts('Charles Louis Xavier Joseph de la Vall{\`e}e Poussin', [['Charles ', 'Louis ', 'Xavier ', 'Joseph '], ['de ', 'la '], [], ['Vall{\`e}e ', 'Poussin']]);
};

subtest "formatNamePart" => sub {
  plan tests => 10;

  sub isFormatNamePart {
    my ($parts, $short, $seperator, $post, $expected) = @_;
    my $name = join('', @$parts);
    is_deeply(formatNamePart($parts, $short, $seperator, $post), $expected, $name);
  }

  # long form
  isFormatNamePart(['Dr ',  'Alex ', 'Bob ', 'Charlotte '], 0, undef, '', 'Dr~Alex Bob~Charlotte');
  isFormatNamePart(['Dr-',  'Alex ', 'Bob ', 'Charlotte '], 0, undef, '', 'Dr-Alex Bob~Charlotte');
  isFormatNamePart(['Dr. ', 'Alex ', 'Bob ', 'Charlotte '], 0, undef, '', 'Dr. Alex Bob~Charlotte');
  isFormatNamePart(['Dr ', 'Charlotte '], 0, undef, '', 'Dr~Charlotte');

  # short form
  isFormatNamePart(['Dr ',  'Alex ', 'Bob ', 'Charlotte '], 1, undef, '', 'D.~A. B.~C');
  isFormatNamePart(['Dr-',  'Alex ', 'Bob ', 'Charlotte '], 1, undef, '', 'D.-A. B.~C');
  isFormatNamePart(['Dr. ', 'Alex ', 'Bob ', 'Charlotte '], 1, undef, '', 'D.~A. B.~C');
  isFormatNamePart(['Dr ', 'Charlotte '], 1, undef, '', 'D.~C');

  # custom seperator
  isFormatNamePart(['Dr ', 'Alex ', 'Bob ', 'Charlotte '], 1, '/', '', 'D/A/B/C');
  isFormatNamePart(['Dr ', 'Alex ', 'Bob ', 'Charlotte '], 0, '/', '', 'Dr/Alex/Bob/Charlotte');
};

subtest "formatName" => sub {
  plan tests => 26;

  sub isFormatName {
    my ($name, $spec, $expected) = @_;
    my ($result, $error) = formatName($name, $spec);
    diag($error) if $error;
    is_deeply($result, $expected, 'format(<' . $name . '>, <' . $spec . '>)');
  }

  # from the official BiBTeX documentation
  isFormatName('Charles Louis Xavier Joseph de la Vall{\`e}e Poussin', '{vv~}{ll}{, jj}{, f}?', 'de~la Vall{\`e}e~Poussin, C.~L. X.~J?');

  # examples from "Names in BibTEX and MlBibTEX", Figure 5 LHS lastname => "Le Clerc De La Herverie"
  isFormatName('von Le Clerc De La Herverie', '{ll}',         'Le~Clerc De La~Herverie');
  isFormatName('von Le Clerc De La Herverie', '{ll/}',        'Le~Clerc De La~Herverie/');
  isFormatName('von Le Clerc De La Herverie', '{ll/,}',       'Le~Clerc De La~Herverie/,');
  isFormatName('von Le Clerc De La Herverie', '{ll{/},}',     'Le/Clerc/De/La/Herverie,');
  isFormatName('von Le Clerc De La Herverie', '{ll{},}',      'LeClercDeLaHerverie,');
  isFormatName('von Le Clerc De La Herverie', '{ll~}',        'Le~Clerc De La~Herverie ');
  isFormatName('von Le Clerc De La Herverie', '{ll~~}',       'Le~Clerc De La~Herverie~');
  isFormatName('von Le Clerc De La Herverie', '{ll{~}~}',     'Le~Clerc~De~La~Herverie ');
  isFormatName('von Le Clerc De La Herverie', '{ll{~}~~}',    'Le~Clerc~De~La~Herverie~');
  isFormatName('von Le Clerc De La Herverie', '{ll{/},~}',    'Le/Clerc/De/La/Herverie, ');
  isFormatName('von Le Clerc De La Herverie', '{ll{/}~,~}',   'Le/Clerc/De/La/Herverie~, ');
  isFormatName('von Le Clerc De La Herverie', '{ll{/}~~,~~}', 'Le/Clerc/De/La/Herverie~~,~');

  # example from "Names in BibTEX and MlBibTEX", Figure 5 LHS lastname => "Zeb Chillicothe Mantey"
  isFormatName('von Zeb Chillicothe Mantey', '{ll}', 'Zeb Chillicothe~Mantey');

# examples from "Names in BibTEX and MlBibTEX", Figure 5 RHS firstname => "Jean-Michel-Georges-Albert"
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f}',         'J.-M.-G.-A');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f/}',        'J.-M.-G.-A/');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f/,}',       'J.-M.-G.-A/,');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{/},}',     'J/M/G/A,');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{},}',      'JMGA,');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f~}',        'J.-M.-G.-A ');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f~~}',       'J.-M.-G.-A~');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{~}~}',     'J~M~G~A ');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{~}~~}',    'J~M~G~A~');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{/},~}',    'J/M/G/A, ');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{/}~,~}',   'J/M/G/A~, ');
  isFormatName('Jean-Michel-Georges-Albert Lastname', '{f{/}~~,~~}', 'J/M/G/A~~,~');
};
