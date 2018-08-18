# /=====================================================================\ #
# |  BiBTeXML::Compiler::Program                                        | #
# | .bst -> perl compile program implementation                         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Compiler::Program;
use strict;
use warnings;

use BiBTeXML::Compiler::Utils;
use BiBTeXML::Compiler::Calls;
use BiBTeXML::Compiler::Block;

use base qw(Exporter);
our @EXPORT = (
  qw( &compileProgram )
);

# Compiles a program from (parsed) .bst
# into a string representing perl
sub compileProgram {
  my ($program) = @_;

  ### Setup a context containing everything that can be declared
  my %context = (
    'crossref'  => 'BUILTIN_ENTRY_FIELD',
    'sort.key$' => 'BUILTIN_ENTRY_STRING',

    'entry.max$'  => 'BUILTIN_GLOBAL_INTEGER',
    'global.max$' => 'BUILTIN_GLOBAL_INTEGER',

    '>'  => 'BUILTIN_FUNCTION',
    '<'  => 'BUILTIN_FUNCTION',
    '='  => 'BUILTIN_FUNCTION',
    '+'  => 'BUILTIN_FUNCTION',
    '-'  => 'BUILTIN_FUNCTION',
    '*'  => 'BUILTIN_FUNCTION',
    ':=' => 'BUILTIN_FUNCTION',

    'add.period$'   => 'BUILTIN_FUNCTION',
    'call.type$'    => 'BUILTIN_FUNCTION',
    'change.case$'  => 'BUILTIN_FUNCTION',
    'chr.to.int$'   => 'BUILTIN_FUNCTION',
    'cite$'         => 'BUILTIN_FUNCTION',
    'duplicate$'    => 'BUILTIN_FUNCTION',
    'empty$'        => 'BUILTIN_FUNCTION',
    'format.name$ ' => 'BUILTIN_FUNCTION',
    'if$'           => 'BUILTIN_FUNCTION',
    'int.to.chr$'   => 'BUILTIN_FUNCTION',
    'int.to.str$'   => 'BUILTIN_FUNCTION',
    'missing$'      => 'BUILTIN_FUNCTION',
    'newline$'      => 'BUILTIN_FUNCTION',
    'num.names$'    => 'BUILTIN_FUNCTION',
    'pop$'          => 'BUILTIN_FUNCTION',
    'preamble$'     => 'BUILTIN_FUNCTION',
    'purify$'       => 'BUILTIN_FUNCTION',
    'quote$'        => 'BUILTIN_FUNCTION',
    'skip$ '        => 'BUILTIN_FUNCTION',
    'stack$'        => 'BUILTIN_FUNCTION',
    'substring$'    => 'BUILTIN_FUNCTION',
    'swap$'         => 'BUILTIN_FUNCTION',
    'text.length$'  => 'BUILTIN_FUNCTION',
    'text.prefix$'  => 'BUILTIN_FUNCTION',
    'top$ '         => 'BUILTIN_FUNCTION',
    'type$'         => 'BUILTIN_FUNCTION',
    'warning$'      => 'BUILTIN_FUNCTION',
    'while$'        => 'BUILTIN_FUNCTION',
    'width$'        => 'BUILTIN_FUNCTION',
    'write$'        => 'BUILTIN_FUNCTION',
  );

  # TODO: Start going over the different commands and compiling all of them
}

1;

