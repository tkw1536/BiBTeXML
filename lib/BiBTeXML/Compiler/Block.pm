# /=====================================================================\ #
# |  BiBTeXML::Compiler::Block                                          | #
# | .bst -> perl compile block implementation                           | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Compiler::Block;
use strict;
use warnings;

use BiBTeXML::Compiler::Utils;
use BiBTeXML::Compiler::Calls;

use base qw(Exporter);
our @EXPORT = (
  qw( &compileQuote ),
  qw( &compileArgument ),
  qw( &compileReference ),
  qw( &compileLiteral ),
  qw( &compileInlineBlock ),
);

sub compileInstruction {
  my ($instruction) = @_;

  my $type = $instruction->getKind;
  if ($type eq 'LITERAL') {
    return compileLiteral(@_);
  } elsif ($type eq 'REFERENCE') {
    return compileReference(@_);
  } elsif ($type eq 'BLOCK') {
    return compileInlineBlock(@_);
  } elsif ($type eq 'QUOTE') {
    return compileQuote(@_);
  } elsif ($type eq 'NUMBER') {
    return compileArgument(@_);
  } else {
    return undef, "Unknown instruction of type $type " . $instruction->getLocationString;
  }
}

# compiles a single literal
sub compileLiteral {
  my ($variable, $indent, %context) = @_;
  return undef, 'Expected a LITERAL ' . $variable->getLocationString unless $variable->getKind eq 'LITERAL';

  # lookup type of variable
  my $name = $variable->getValue;    # TODO: Normalization?
  return undef, "Unknown literal $name in literal " . $variable->getLocationString unless exists($context{$name});
  my $type = $context{$name};

  my $result;
  if ($type eq 'GLOBAL_STRING' or $type eq 'BUILTIN_GLOBAL_STRING') {
    $result = callPushGlobalString($variable);
  } elsif ($type eq 'GLOBAL_INTEGER' or $type eq 'BUILTIN_GLOBAL_INTEGER') {
    $result = callPushGlobalInteger($variable);
  } elsif ($type eq 'ENTRY_FIELD' or $type eq 'BUILTIN_ENTRY_FIELD') {
    $result = callLookupEntryField($variable);
  } elsif ($type eq 'ENTRY_STRING' or $type eq 'BUILTIN_ENTRY_STRING') {
    $result = callPushEntryString($variable);
  } elsif ($type eq 'ENTRY_INTEGER' or $type eq 'BUILTIN_ENTRY_INTEGER') {
    $result = callPushEntryInteger($variable);
  } elsif ($type eq 'FUNCTION') {
    $result .= callCallFunction($variable);
  } elsif ($type eq 'BUILTIN_FUNCTION') {
    $result .= callCallBuiltin($variable);
  } else {
    return undef, "Unknown variable type $type in literal " . $variable->getLocationString;
  }
  return makeIndent($indent) . $result . "\n";
}

# compiles a single reference
sub compileReference {
  my ($reference, $indent, %context) = @_;
  return undef, 'Expected a REFERENCE ' . $reference->getLocationString unless $reference->getKind eq 'REFERENCE';

  # lookup type of variable
  my $name = $reference->getValue;    # TODO: Normalization?
  return undef, "Unknown literal $name in reference " . $reference->getLocationString unless exists($context{$name});
  my $type = $context{$name};

  my $result;
  if ($type eq 'GLOBAL_STRING' or $type eq 'BUILTIN_GLOBAL_STRING') {
    $result = callLookupGlobalString($reference);
  } elsif ($type eq 'GLOBAL_INTEGER' or $type eq 'BUILTIN_GLOBAL_INTEGER') {
    $result = callLookupGlobalInteger($reference);
  } elsif ($type eq 'ENTRY_STRING' or $type eq 'BUILTIN_ENTRY_STRING') {
    $result = callLookupEntryString($reference);
  } elsif ($type eq 'ENTRY_INTEGER' or $type eq 'BUILTIN_ENTRY_INTEGER') {
    $result = callLookupEntryInteger($reference);
  } elsif ($type eq 'FUNCTION') {
    $result .= callLookupFunction($reference);
  } elsif ($type eq 'BUILTIN_FUNCTION') {
    $result .= callLookupBuiltin($reference);
  } else {
    return undef, "Unsupported variable type $type in reference " . $reference->getLocationString;
  }

  return makeIndent($indent) . $result . "\n";
}

sub compileInlineBlock {
  my ($block, $indent, %context) = @_;
  return undef, 'Expected a BLOCK ' . $block->getLocationString unless $block->getKind eq 'BLOCK';

  my $buffer = makeIndent($indent) . callLookupBlockStart . "sub { \n";

  my @instructions = @{ $block->getValue };
  my ($compilation, $compilationError);
  foreach my $instruction (@instructions) {
    ($compilation, $compilationError) = compileInstruction($instruction, $indent + 1, %context);
    return $compilation, $compilationError unless defined($compilation);
    $buffer .= $compilation;
  }

  # TODO: Compile all the things inside with indent + 1
  $buffer .= makeIndent($indent) . '}' . callLookupBlockEnd($block) . "\n";
  return $buffer;
}

# compile a single quote
sub compileQuote {
  my ($quote, $indent) = @_;
  return undef, 'Expected a QUOTE ' . $quote->getLocationString unless $quote->getKind eq 'QUOTE';

  return makeIndent($indent) . callPushString($quote) . "\n";
}

# compiles a single number
sub compileArgument {
  my ($number, $indent) = @_;
  return undef, 'Expected a NUMBER ' . $number->getLocationString unless $number->getKind eq 'NUMBER';
  return makeIndent($indent) . callPushArgument($number) . "\n";
}

1;

