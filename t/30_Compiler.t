use BiBTeXML::Common::Test;
use Test::More tests => 6;

subtest "requirements" => sub {
  plan tests => 2;

  use_ok("BiBTeXML::BibStyle");
  use_ok("BiBTeXML::Compiler");
};

subtest "compileInteger" => sub {
  plan tests => 2;

  doesCompileInteger('integer 1', StyString('NUMBER', 1, [(1, 1, 1, 3)]), 'pushInteger($context, 1, StyString(\'NUMBER\', 1, [(1, 1, 1, 3)])); ');
  doesCompileInteger('integer 2', StyString('NUMBER', 2, [(1, 5, 1, 7)]), 'pushInteger($context, 2, StyString(\'NUMBER\', 2, [(1, 5, 1, 7)])); ');

  sub doesCompileInteger {
    my ($name, $integer, @compilation) = @_;
    my ($result) = compileInteger($integer, 0);
    is($result, join("\n", @compilation) . "\n", $name);
  }
};

subtest "compileQuote" => sub {
  plan tests => 2;

  doesCompileQuote('quote with spaces', StyString('QUOTE', 'hello world', [(1, 1, 1, 15)]), 'pushString($context, \'hello world\', StyString(\'QUOTE\', \'hello world\', [(1, 1, 1, 15)])); ');
  doesCompileQuote('empty quote', StyString('QUOTE', '', [(1, 1, 1, 2)]), 'pushString($context, \'\', StyString(\'QUOTE\', \'\', [(1, 1, 1, 2)])); ');

  sub doesCompileQuote {
    my ($name, $quote, @compilation) = @_;
    my ($result, $error) = compileQuote($quote, 0);
    is($result, join("\n", @compilation) . "\n", $name);
  }
};

subtest "compileVariable" => sub {
  plan tests => 12;

  doesCompileReference('GLOBAL_STRING', 'example', 'lookupGlobalString($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileReference('BUILTIN_GLOBAL_STRING', 'example', 'lookupGlobalString($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');

  doesCompileReference('GLOBAL_INTEGER', 'example', 'lookupGlobalInteger($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileReference('BUILTIN_GLOBAL_INTEGER', 'entry.max$', 'lookupGlobalInteger($context, \'entry.max$\', StyString(\'REFERENCE\', \'entry.max$\', [(1, 2, 1, 9)])); ');

  doesCompileReference('ENTRY_FIELD', 'example', 'lookupEntryField($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileReference('BUILTIN_ENTRY_FIELD', 'crossref', 'lookupEntryField($context, \'crossref\', StyString(\'REFERENCE\', \'crossref\', [(1, 2, 1, 9)])); ');

  doesCompileReference('ENTRY_STRING', 'example', 'lookupEntryString($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileReference('BUILTIN_ENTRY_STRING', 'sort.key$', 'lookupEntryString($context, \'sort.key$\', StyString(\'REFERENCE\', \'sort.key$\', [(1, 2, 1, 9)])); ');

  doesCompileReference('ENTRY_INTEGER', 'example', 'lookupEntryInteger($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileReference('BUILTIN_ENTRY_INTEGER', 'example', 'lookupEntryInteger($context, \'example\', StyString(\'REFERENCE\', \'example\', [(1, 2, 1, 9)])); ');

  doesCompileReference('FUNCTION', 'h.e_ll0_:=', 'lookupFunction($context, \&bst__h_o_e__ll0___co__eq_, StyString(\'REFERENCE\', \'h.e_ll0_:=\', [(1, 2, 1, 9)])); ');
  doesCompileReference('BUILTIN_FUNCTION', 'sort.key$', 'lookupFunction($context, \&builtin__sort_o_key_S_, StyString(\'REFERENCE\', \'sort.key$\', [(1, 2, 1, 9)])); ');

  sub doesCompileReference {
    my ($type, $value, @compilation) = @_;
    my $reference = StyString('REFERENCE', $value, [(1, 2, 1, 9)]);
    my %context = ($value => $type);

    my ($result, $error) = compileReference($reference, 0, %context);

    is($result, join("\n", @compilation) . "\n", $type);
  }
};

subtest "compileLiteral" => sub {
  plan tests => 12;

  doesCompileLiteral('GLOBAL_STRING', 'example', 'pushGlobalString($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileLiteral('BUILTIN_GLOBAL_STRING', 'example', 'pushGlobalString($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');

  doesCompileLiteral('GLOBAL_INTEGER', 'example', 'pushGlobalInteger($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileLiteral('BUILTIN_GLOBAL_INTEGER', 'entry.max$', 'pushGlobalInteger($context, \'entry.max$\', StyString(\'LITERAL\', \'entry.max$\', [(1, 2, 1, 9)])); ');

  doesCompileLiteral('ENTRY_FIELD', 'example', 'pushEntryField($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileLiteral('BUILTIN_ENTRY_FIELD', 'crossref', 'pushEntryField($context, \'crossref\', StyString(\'LITERAL\', \'crossref\', [(1, 2, 1, 9)])); ');

  doesCompileLiteral('ENTRY_STRING', 'example', 'pushEntryString($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileLiteral('BUILTIN_ENTRY_STRING', 'sort.key$', 'pushEntryString($context, \'sort.key$\', StyString(\'LITERAL\', \'sort.key$\', [(1, 2, 1, 9)])); ');

  doesCompileLiteral('ENTRY_INTEGER', 'example', 'pushEntryInteger($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');
  doesCompileLiteral('BUILTIN_ENTRY_INTEGER', 'example', 'pushEntryInteger($context, \'example\', StyString(\'LITERAL\', \'example\', [(1, 2, 1, 9)])); ');

  doesCompileLiteral('FUNCTION', 'h.e_ll0_:=', 'bst__h_o_e__ll0___co__eq_($context, StyString(\'LITERAL\', \'h.e_ll0_:=\', [(1, 2, 1, 9)])); ');
  doesCompileLiteral('BUILTIN_FUNCTION', 'sort.key$', 'builtin__sort_o_key_S_($context, StyString(\'LITERAL\', \'sort.key$\', [(1, 2, 1, 9)])); ');

  sub doesCompileLiteral {
    my ($type, $value, @compilation) = @_;
    my $reference = StyString('LITERAL', $value, [(1, 2, 1, 9)]);
    my %context = ($value => $type);

    my ($result, $error) = compileLiteral($reference, 0, %context);

    is($result, join("\n", @compilation) . "\n", $type);
  }
};

subtest "compileInlineBlock" => sub {
  plan tests => 2;

  doesCompileInlineBlock('simple block', "inline_block_simple.txt", StyString('BLOCK', [(StyString('QUOTE', 'content', [(1, 5, 1, 10)]))], [(1, 4, 1, 11)]));
  doesCompileInlineBlock('nested block', "inline_block_complex.txt", StyString('BLOCK', [(StyString('QUOTE', 'outer', [(1, 1, 1, 7)]), StyString('BLOCK', [(StyString('QUOTE', 'inner', [(2, 2, 2, 7)]))], [(2, 1, 2, 8)]), StyString('QUOTE', 'outer', [(3, 1, 3, 7)]))], [(1, 4, 3, 8)]));

  sub doesCompileInlineBlock {
    my ($name, $path, $block) = @_;
    my ($result) = compileInlineBlock($block, 0);
    is($result, slurp(fixture(__FILE__, "compiler", $path)), $name);
  }
};

1;
