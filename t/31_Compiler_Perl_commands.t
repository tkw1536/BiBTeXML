use BiBTeXML::Common::Test;
use Test::More tests => 11;

my $target = "BiBTeXML::Compiler::Target::Perl";
my $base = fixture(__FILE__, "compiler", "perl", "commands", "");

sub doesCompileCommand {
  my ($kind, $name, $output, $input, @args) = @_;
  my $compiler = \&{"BiBTeXML::Compiler::Program::compile$kind"};
  my ($result, $error) = &{$compiler}($target, $input, 0, @args);
  diag($error) if $error;
  # puts($base . $output, $result); # to generate test cases
  is(slurp($base . $output), $result, $name);
}

subtest "requirements" => sub {
  plan tests => 3;

  use_ok("BiBTeXML::BibStyle");
  use_ok("BiBTeXML::Compiler");
  use_ok("$target");
};

subtest "compileEntry" => sub {
  plan tests => 1;

  my $entry = StyCommand(StyString('LITERAL', 'ENTRY', [(0, 0, 1, 5)]), [(StyString('BLOCK', [(StyString('LITERAL', 'a', [(2, 4, 2, 5)]), StyString('LITERAL', 'b', [(2, 6, 2, 7)]), StyString('LITERAL', 'c', [(2, 8, 2, 9)]))], [(2, 2, 2, 11)]), StyString('BLOCK', [(StyString('LITERAL', 'd', [(3, 4, 3, 5)]), StyString('LITERAL', 'e', [(3, 6, 3, 7)]))], [(3, 2, 3, 9)]), StyString('BLOCK', [(StyString('LITERAL', 'f', [(4, 4, 4, 5)]))], [(4, 2, 4, 7)]))], [(0, 0, 4, 7)]);
  doesCompileCommand('Entry', 'entry', '01_entry.txt', $entry);
};

subtest "compileStrings" => sub {
  plan tests => 1;

  my $strings = StyCommand(StyString('LITERAL', 'STRINGS', [(0, 0, 1, 7)]), [(StyString('BLOCK', [(StyString('LITERAL', 'a', [(2, 4, 2, 5)]), StyString('LITERAL', 'b', [(2, 6, 2, 7)]), StyString('LITERAL', 'c', [(2, 8, 2, 9)]), StyString('LITERAL', 'd', [(2, 10, 2, 11)]), StyString('LITERAL', 'e', [(2, 12, 2, 13)]), StyString('LITERAL', 'f', [(2, 14, 2, 15)]))], [(2, 2, 2, 17)]))], [(0, 0, 2, 17)]);
  doesCompileCommand('Strings', 'strings', '02_strings.txt', $strings);
};

subtest "compileIntegers" => sub {
  plan tests => 1;

  my $integers = StyCommand(StyString('LITERAL', 'INTEGERS', [(0, 0, 1, 8)]), [(StyString('BLOCK', [(StyString('LITERAL', 'a', [(2, 4, 2, 5)]), StyString('LITERAL', 'b', [(2, 6, 2, 7)]), StyString('LITERAL', 'c', [(2, 8, 2, 9)]), StyString('LITERAL', 'd', [(2, 10, 2, 11)]), StyString('LITERAL', 'e', [(2, 12, 2, 13)]), StyString('LITERAL', 'f', [(2, 14, 2, 15)]))], [(2, 2, 2, 17)]))], [(0, 0, 2, 17)]);
  doesCompileCommand('Integers', 'integers', '03_integers.txt', $integers);
};

subtest "compileMacro" => sub {
  plan tests => 1;

  my $macro = StyCommand(StyString('LITERAL', 'MACRO', [(0, 0, 1, 5)]), [(StyString('BLOCK', [(StyString('LITERAL', 'jan', [(1, 7, 1, 10)]))], [(1, 6, 1, 11)]), StyString('BLOCK', [(StyString('QUOTE', 'January', [(1, 13, 1, 22)]))], [(1, 12, 1, 23)]))], [(0, 0, 1, 23)]);
  doesCompileCommand('Macro', 'macro', '04_macro.txt', $macro);
};

subtest "compileFunction" => sub {
  plan tests => 1;

  my $function = StyCommand(StyString('LITERAL', 'FUNCTION', [(0, 0, 1, 8)]), [(StyString('BLOCK', [(StyString('LITERAL', 'chop.word', [(1, 10, 1, 19)]))], [(1, 9, 1, 20)]), StyString('BLOCK', [(StyString('REFERENCE', 's', [(2, 2, 2, 4)]), StyString('LITERAL', ':=', [(2, 5, 2, 7)]), StyString('REFERENCE', 'len', [(3, 2, 3, 6)]), StyString('LITERAL', ':=', [(3, 7, 3, 9)]), StyString('LITERAL', 's', [(4, 2, 4, 3)]), StyString('NUMBER', 1, [(4, 4, 4, 6)]), StyString('LITERAL', 'len', [(4, 7, 4, 10)]), StyString('LITERAL', 'substring$', [(4, 11, 4, 21)]), StyString('LITERAL', '=', [(4, 22, 4, 23)]), StyString('BLOCK', [(StyString('LITERAL', 's', [(5, 6, 5, 7)]), StyString('LITERAL', 'len', [(5, 8, 5, 11)]), StyString('NUMBER', 1, [(5, 12, 5, 14)]), StyString('LITERAL', '+', [(5, 15, 5, 16)]), StyString('LITERAL', 'global.max$', [(5, 17, 5, 28)]), StyString('LITERAL', 'substring$', [(5, 29, 5, 39)]))], [(5, 4, 5, 41)]), StyString('REFERENCE', 's', [(6, 4, 6, 6)]), StyString('LITERAL', 'if$', [(7, 2, 7, 5)]))], [(1, 21, 8, 2)]))], [(0, 0, 8, 2)]);
  my %context = (
    's'           => 'GLOBAL_STRING',
    ':='          => 'BUILTIN_FUNCTION',
    'len'         => 'GLOBAL_INTEGER',
    'substring$'  => 'BUILTIN_FUNCTION',
    '='           => 'BUILTIN_FUNCTION',
    '+'           => 'BUILTIN_FUNCTION',
    'global.max$' => 'BUILTIN_GLOBAL_INTEGER',
    'if$'         => 'BUILTIN_FUNCTION'
  );
  doesCompileCommand('Function', 'function', '05_function.txt', $function, %context);
};

subtest "compileExecute" => sub {
  plan tests => 2;

  my $execute = StyCommand(StyString('LITERAL', 'EXECUTE', [(0, 0, 1, 7)]), [(StyString('BLOCK', [(StyString('LITERAL', 'example', [(1, 9, 1, 16)]))], [(1, 8, 1, 17)]))], [(0, 0, 1, 17)]);

  doesCompileCommand('Execute', 'user-defined execute', '06_execute_a.txt', $execute, example => 'FUNCTION');
  doesCompileCommand('Execute', 'builtin execute', '06_execute_b.txt', $execute, example => 'BUILTIN_FUNCTION');
};

subtest "compileRead" => sub {
  plan tests => 1;

  my $read = StyCommand(StyString('LITERAL', 'READ', [(0, 0, 1, 4)]), [()], [(0, 0, 1, 4)]);
  doesCompileCommand('Read', 'read', '07_read.txt', $read);
};

subtest "compileSort" => sub {
  plan tests => 1;

  my $sort = StyCommand(StyString('LITERAL', 'SORT', [(0, 0, 1, 4)]), [()], [(0, 0, 1, 4)]);
  doesCompileCommand('Sort', 'sort', '08_sort.txt', $sort);
};

subtest "compileIterate" => sub {
  plan tests => 2;

  my $iterate = StyCommand(StyString('LITERAL', 'ITERATE', [(0, 0, 1, 7)]), [(StyString('BLOCK', [(StyString('LITERAL', 'example', [(1, 9, 1, 16)]))], [(1, 8, 1, 17)]))], [(0, 0, 1, 17)]);

  doesCompileCommand('Iterate', 'user-defined iterate', '09_iterate_a.txt', $iterate, example => 'FUNCTION');
  doesCompileCommand('Iterate', 'builtin iterate', '09_iterate_b.txt', $iterate, example => 'BUILTIN_FUNCTION');
};

subtest "compileReverse" => sub {
  plan tests => 2;

  my $reverse = StyCommand(StyString('LITERAL', 'REVERSE', [(0, 0, 1, 7)]), [(StyString('BLOCK', [(StyString('LITERAL', 'example', [(1, 9, 1, 16)]))], [(1, 8, 1, 17)]))], [(0, 0, 1, 17)]);

  doesCompileCommand('Reverse', 'user-defined reverse', '10_reverse_a.txt', $reverse, example => 'FUNCTION');
  doesCompileCommand('Reverse', 'builtin reverse', '10_reverse_b.txt', $reverse, example => 'BUILTIN_FUNCTION');
};

1;
