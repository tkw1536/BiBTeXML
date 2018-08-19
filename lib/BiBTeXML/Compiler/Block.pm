# /=====================================================================\ #
# |  BiBTeXML::Compiler::Block                                          | #
# | .bst compile block implementation                                   | #
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
  qw( &compileInteger ),
  qw( &compileReference ),
  qw( &compileLiteral ),
  qw( &compileInlineBlock &compileBlockBody ),
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
    return compileInteger(@_);
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
    $result = callPushEntryField($variable);
  } elsif ($type eq 'ENTRY_STRING' or $type eq 'BUILTIN_ENTRY_STRING') {
    $result = callPushEntryString($variable);
  } elsif ($type eq 'ENTRY_INTEGER' or $type eq 'BUILTIN_ENTRY_INTEGER') {
    $result = callPushEntryInteger($variable);
  } elsif ($type eq 'FUNCTION') {
    $result .= callCallFunction($variable);
  } elsif ($type eq 'BUILTIN_FUNCTION') {
    $result .= callCallBuiltin($variable);
  } else {
    return undef, "Attempted to resolve " . $name . " of type $type in literal " . $variable->getLocationString;
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
  } elsif ($type eq 'ENTRY_FIELD' or $type eq 'BUILTIN_ENTRY_FIELD') {
    $result = callLookupEntryField($reference);
  } elsif ($type eq 'ENTRY_INTEGER' or $type eq 'BUILTIN_ENTRY_INTEGER') {
    $result = callLookupEntryInteger($reference);
  } elsif ($type eq 'FUNCTION') {
    $result .= callLookupFunction($reference);
  } elsif ($type eq 'BUILTIN_FUNCTION') {
    $result .= callLookupBuiltin($reference);
  } else {
    return undef, "Attempted to reference " . $name . " of type $type in reference " . $reference->getLocationString;
  }

  return makeIndent($indent) . $result . "\n";
}

# compiles a single inline block
sub compileInlineBlock {
  my ($block, $indent, %context) = @_;
  return undef, 'Expected a BLOCK ' . $block->getLocationString unless $block->getKind eq 'BLOCK';

  my ($body, $error) = compileBlockBody($block, $indent, undef, %context);
  return $body, $error if defined($error);

  return makeIndent($indent) . callPushFunction($block, $body) . "\n";
}

# compiles the body of a block
sub compileBlockBody {
  my ($block, $indent, $name, %context) = @_;
  return undef, 'Expected a BLOCK ' . $block->getLocationString unless $block->getKind eq 'BLOCK';

  # start a new sub and read the context
  my $buffer = "sub " . (defined($name) ? escapeFunctionName($name) . ' ' : '') . "{ \n";
  $buffer .= makeIndent($indent + 1) . 'my ($context) = @_; ' . "\n";

  # compile all the instructions
  my @instructions = @{ $block->getValue };
  my ($compilation, $compilationError);
  foreach my $instruction (@instructions) {
    ($compilation, $compilationError) = compileInstruction($instruction, $indent + 1, %context);
    return $compilation, $compilationError unless defined($compilation);
    $buffer .= $compilation;
  }

  # close the sub
  $buffer .= makeIndent($indent) . "}";
  return $buffer;
}

# compile a single quote
sub compileQuote {
  my ($quote, $indent) = @_;
  return undef, 'Expected a QUOTE ' . $quote->getLocationString unless $quote->getKind eq 'QUOTE';

  return makeIndent($indent) . callPushString($quote) . "\n";
}

# compiles a single number
sub compileInteger {
  my ($number, $indent) = @_;
  return undef, 'Expected a NUMBER ' . $number->getLocationString unless $number->getKind eq 'NUMBER';
  return makeIndent($indent) . callPushInteger($number) . "\n";
}

1;

