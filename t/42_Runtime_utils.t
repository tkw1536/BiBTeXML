use BiBTeXML::Common::Test;
use Test::More tests => 5;

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
  plan tests => 9;

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
