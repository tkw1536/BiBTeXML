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
  qw( &compileProgram ),
  qw( &compileCommand ),
  qw( &compileEntry &compileStrings &compileIntegers &compileMacro &compileFunction &compileExecute &compileRead &compileSort &compileIterate &compileReverse )
);

# Compiles a program from (parsed) .bst
# into a string representing perl
sub compileProgram {
  my ($program) = @_;

  # add some header for the code to be compiled
  my $code = "sub { \n";
  $code .= makeIndent(1) . "# code automatically generated BiBTeXML \n";
  $code .= makeIndent(1) . 'use BiBTeXML::Runtime; ' . "\n";
  $code .= makeIndent(1) . 'my ($context) = @_; ' . "\n";

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

    'add.period$'  => 'BUILTIN_FUNCTION',
    'call.type$'   => 'BUILTIN_FUNCTION',
    'change.case$' => 'BUILTIN_FUNCTION',
    'chr.to.int$'  => 'BUILTIN_FUNCTION',
    'cite$'        => 'BUILTIN_FUNCTION',
    'duplicate$'   => 'BUILTIN_FUNCTION',
    'empty$'       => 'BUILTIN_FUNCTION',
    'format.name$' => 'BUILTIN_FUNCTION',
    'if$'          => 'BUILTIN_FUNCTION',
    'int.to.chr$'  => 'BUILTIN_FUNCTION',
    'int.to.str$'  => 'BUILTIN_FUNCTION',
    'missing$'     => 'BUILTIN_FUNCTION',
    'newline$'     => 'BUILTIN_FUNCTION',
    'num.names$'   => 'BUILTIN_FUNCTION',
    'pop$'         => 'BUILTIN_FUNCTION',
    'preamble$'    => 'BUILTIN_FUNCTION',
    'purify$'      => 'BUILTIN_FUNCTION',
    'quote$'       => 'BUILTIN_FUNCTION',
    'skip$'        => 'BUILTIN_FUNCTION',
    'stack$'       => 'BUILTIN_FUNCTION',
    'substring$'   => 'BUILTIN_FUNCTION',
    'swap$'        => 'BUILTIN_FUNCTION',
    'text.length$' => 'BUILTIN_FUNCTION',
    'text.prefix$' => 'BUILTIN_FUNCTION',
    'top$'         => 'BUILTIN_FUNCTION',
    'type$'        => 'BUILTIN_FUNCTION',
    'warning$'     => 'BUILTIN_FUNCTION',
    'while$'       => 'BUILTIN_FUNCTION',
    'width$'       => 'BUILTIN_FUNCTION',
    'write$'       => 'BUILTIN_FUNCTION',
  );

  # compile each of the commands
  my ($command, $result, $error);
  foreach $command (@$program) {
    ($result, $error, %context) = compileCommand($command, 1, %context);
    return $result, $error if defined($error);
    $code .= $result;
  }

  # add a little bit of code at the bottom
  $code .= "\n\n";
  $code .= makeIndent(1) . 'return $context; ' . "\n";
  $code .= makeIndent(1) . "# end of automatically generated code \n";
  $code .= "}";
  return $code;

}

# compiles a command in a given context
# returns $command, $error, %context
sub compileCommand {
  my ($command, $indent, %context) = @_;
  my $name = $command->getName->getValue;
  if ($name eq 'ENTRY') { return compileEntry($command, $indent, %context);

  } elsif ($name eq 'STRINGS') { return compileStrings($command, $indent, %context);
  } elsif ($name eq 'INTEGERS') { return compileIntegers($command, $indent, %context);

  } elsif ($name eq 'MACRO') { return compileMacro($command, $indent, %context);
  } elsif ($name eq 'FUNCTION') { return compileFunction($command, $indent, %context);

  } elsif ($name eq 'EXECUTE') { return compileExecute($command, $indent, %context);

  } elsif ($name eq 'READ') { return compileRead($command, $indent, %context);
  } elsif ($name eq 'SORT') { return compileSort($command, $indent, %context);

  } elsif ($name eq 'ITERATE') { return compileIterate($command, $indent, %context);
  } elsif ($name eq 'REVERSE') { return compileIterate($command, $indent, %context);

  } else {
    return undef, "Unknown command $name" . $command->getLocationString;
  }
}

# compiles an ENTRY command
sub compileEntry {
  my ($entry, $indent, %context) = @_;
  return undef, 'Expected an ENTRY ' . $entry->getLocationString unless $entry->getName->getValue eq 'ENTRY';

  my $result = '';
  my ($fields, $integers, $strings) = @{ $entry->getArguments };

  # define entry fields
  my ($field, $name);
  foreach $field (@{ $fields->getValue }) {
    $name = lc($field->getValue);
    return undef, 'unable to define entry field ' . $name . ' ' . $field->getLocationString if defined($context{$name});
    $result .= makeIndent($indent) . callDefineEntryField($field) . "\n";
    $context{$name} = 'ENTRY_FIELD';
  }

  # define entry fields
  my ($integer);
  foreach $integer (@{ $integers->getValue }) {
    $name = $integer->getValue;
    return undef, 'unable to define entry integer ' . $name . ' ' . $integer->getLocationString if defined($context{$name});
    $result .= makeIndent($indent) . callDefineEntryInteger($integer) . "\n";
    $context{$name} = 'ENTRY_INTEGER';
  }

  # define entry strings
  my ($string);
  foreach $string (@{ $strings->getValue }) {
    $name = $string->getValue;
    return undef, 'unable to define entry string ' . $name . ' ' . $string->getLocationString if defined($context{$name});
    $result .= makeIndent($indent) . callDefineEntryString($string) . "\n";
    $context{$name} = 'ENTRY_STRING';
  }

  return $result, undef, %context;
}

# compiles a STRINGS command
sub compileStrings {
  my ($strings, $indent, %context) = @_;
  return undef, 'Expected a STRINGS ' . $strings->getLocationString unless $strings->getName->getValue eq 'STRINGS';

  my $result = '';
  my ($args) = @{ $strings->getArguments };

  # define global strings
  my ($string, $name);
  foreach $string (@{ $args->getValue }) {
    $name = $string->getValue;
    return undef, 'unable to define global string ' . $name . ' ' . $string->getLocationString if defined($context{$name});
    $result .= makeIndent($indent) . callDefineGlobalString($string) . "\n";
    $context{$name} = 'GLOBAL_STRING';
  }

  return $result, undef, %context;
}

# compiles a INTEGERS command
sub compileIntegers {
  my ($integers, $indent, %context) = @_;
  return undef, 'Expected a INTEGERS ' . $integers->getLocationString unless $integers->getName->getValue eq 'INTEGERS';

  my $result = '';
  my ($args) = @{ $integers->getArguments };

  # define global integers
  my ($integer, $name);
  foreach $integer (@{ $args->getValue }) {
    $name = $integer->getValue;
    return undef, 'unable to define global integer ' . $name . ' ' . $integer->getLocationString if defined($context{$name});
    $result .= makeIndent($indent) . callDefineGlobalInteger($integer) . "\n";
    $context{$name} = 'GLOBAL_INTEGER';
  }

  return $result, undef, %context;
}

sub compileMacro {
  my ($macro, $indent, %context) = @_;
  return undef, 'Expected a MACRO ' . $macro->getLocationString unless $macro->getName->getValue eq 'MACRO';

  my ($name, $value) = @{ $macro->getArguments };

  # read the macro name
  my @names = @{ $name->getValue };
  return undef, 'Expected exactly one macro name ' . $name->getLocationString . "\n" unless scalar(@names) eq 1;
  $name = $names[0];

  # read the macro value
  my @values = @{ $value->getValue };
  return undef, 'Expected exactly one macro value ' . $value->getLocationString . "\n" unless scalar(@values) eq 1;
  $value = $values[0];

  return makeIndent($indent) . callDefineMacro($name, $value), undef, %context;
}

sub compileFunction {
  my ($function, $indent, %context) = @_;
  return undef, 'Expected a FUNCTION ' . $function->getLocationString unless $function->getName->getValue eq 'FUNCTION';

  my ($name, $block) = @{ $function->getArguments };
  my @names = @{ $name->getValue };
  return undef, 'Expected exactly one function name ' . $name->getLocationString . "\n" unless scalar(@names) eq 1;
  $name = $names[0];

  return undef, 'Can not redefine funtion ' . $name if defined($context{ $name->getValue });

  my ($body, $error) = compileBlockBody($block, $indent, $name->getValue, %context);
  return $body, $error if defined($error);

  $context{ $name->getValue } = 'FUNCTION';
  return makeIndent($indent) . $body . "\n", undef, %context;
}

sub compileExecute {
  my ($execute, $indent, %context) = @_;
  return undef, 'Expected an EXECUTE ' . $execute->getLocationString unless $execute->getName->getValue eq 'EXECUTE';

  my ($name) = @{ $execute->getArguments };
  my @names = @{ $name->getValue };
  return undef, 'Expected exactly one function name ' . $name->getLocationString . "\n" unless scalar(@names) eq 1;
  $name = $names[0];

  my $kind = $context{ $name->getValue };
  my $call;
  return undef, 'Unknown function ' . $name->getValue . ' ' . $execute->getLocationString unless defined($kind);
  if ($kind eq 'BUILTIN_FUNCTION') {
    $call = callCallBuiltin($name);
  } elsif ($kind eq 'FUNCTION') {
    $call = callCallFunction($name);
  } else {
    return undef, 'Cannot call non-function ' . $name->getValue . ' ' . $execute->getLocationString;
  }

  return makeIndent($indent) . $call . "\n", undef, %context;
}

sub compileRead {
  my ($read, $indent, %context) = @_;
  return undef, 'Expected a READ ' . $read->getLocationString unless $read->getName->getValue eq 'READ';

  return makeIndent($indent) . callReadEntries($read) . "\n", undef, %context;
}

sub compileSort {
  my ($sort, $indent, %context) = @_;
  return undef, 'Expected a SORT ' . $sort->getLocationString unless $sort->getName->getValue eq 'SORT';

  return makeIndent($indent) . callSortEntries($sort) . "\n", undef, %context;
}

sub compileIterate {
  my ($iterate, $indent, %context) = @_;
  return undef, 'Expected an ITERATE ' . $iterate->getLocationString unless $iterate->getName->getValue eq 'ITERATE';

  my ($name) = @{ $iterate->getArguments };
  my @names = @{ $name->getValue };
  return undef, 'Expected exactly one function name ' . $name->getLocationString . "\n" unless scalar(@names) eq 1;
  $name = $names[0];

  my $kind = $context{ $name->getValue };
  my $call;
  return undef, 'Unknown function ' . $name->getValue . ' ' . $iterate->getLocationString unless defined($kind);
  if ($kind eq 'BUILTIN_FUNCTION') {
    $call = callIterateBuiltin($name, $iterate);
  } elsif ($kind eq 'FUNCTION') {
    $call = callIterateFunction($name, $iterate);
  } else {
    return undef, 'Cannot iterate non-function ' . $name->getValue . ' ' . $iterate->getLocationString;
  }

  return makeIndent($indent) . $call . "\n", undef, %context;
}

sub compileReverse {
  my ($reverse, $indent, %context) = @_;
  return undef, 'Expected a REVERSE ' . $reverse->getLocationString unless $reverse->getName->getValue eq 'REVERSE';

  my ($name) = @{ $reverse->getArguments };
  my @names = @{ $name->getValue };
  return undef, 'Expected exactly one function name ' . $name->getLocationString . "\n" unless scalar(@names) eq 1;
  $name = $names[0];

  my $kind = $context{ $name->getValue };
  my $call;
  return undef, 'Unknown function ' . $name->getValue . ' ' . $reverse->getLocationString unless defined($kind);
  if ($kind eq 'BUILTIN_FUNCTION') {
    $call = callReverseBuiltin($name, $reverse);
  } elsif ($kind eq 'FUNCTION') {
    $call = callReverseFunction($name, $reverse);
  } else {
    return undef, 'Cannot reverse non-function ' . $name->getValue . ' ' . $reverse->getLocationString;
  }

  return makeIndent($indent) . $call . "\n", undef, %context;
}

1;

