# /=====================================================================\ #
# |  BiBTeXML::Compiler::Calls                                          | #
# | .bst -> perl compiler runtime encoding                              | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Compiler::Calls;
use strict;
use warnings;

use BiBTeXML::Compiler::Utils;

use base qw(Exporter);
our @EXPORT = (
  qw(&callDefineEntryField &callDefineEntryInteger &callDefineEntryString),
  qw(&callDefineGlobalString &callDefineGlobalInteger),
  qw(&callDefineMacro),
  qw(&callReadEntries &callSortEntries),
  qw(&callIterateFunction &callIterateBuiltin),
  qw(&callReverseFunction &callReverseBuiltin),
  qw(&callPushFunctionStart &callPushFunctionEnd &callPopValue),
  qw(&callPushGlobalString &callPushGlobalInteger &callPushEntryField &callPushEntryString &callPushEntryInteger &callCallFunction &callCallBuiltin),
  qw(&callLookupGlobalString &callLookupGlobalInteger &callLookupEntryField &callLookupEntryString &callLookupEntryInteger &callLookupFunction &callLookupBuiltin),
  qw(&callPushString &callPushInteger),
);

### entry

sub callDefineEntryField {
  my ($styString) = @_;
  return callRuntimeFunction('defineEntryField', escapeString(lc $styString->getValue), $styString);
}

sub callDefineEntryInteger {
  my ($styString) = @_;
  return callRuntimeFunction('defineEntryInteger', escapeString($styString->getValue), $styString);
}

sub callDefineEntryString {
  my ($styString) = @_;
  return callRuntimeFunction('defineEntryString', escapeString($styString->getValue), $styString);
}

### strings

sub callDefineGlobalString {
  my ($styString) = @_;
  return callRuntimeFunction('defineGlobalString', escapeString($styString->getValue), $styString);
}

sub callDefineGlobalInteger {
  my ($styString) = @_;
  return callRuntimeFunction('defineGlobalInteger', escapeString($styString->getValue), $styString);
}

sub callDefineMacro {
  my ($name, $value) = @_;
  return callRuntimeFunction('defineMacro', escapeString(lc $name->getValue), escapeString($value->getValue), $name);
}

### read && sort

sub callReadEntries {
  my ($styString) = @_;
  return callRuntimeFunction('readEntries', $styString);
}

sub callSortEntries {
  my ($styString) = @_;
  return callRuntimeFunction('sortEntries', $styString);
}

### iterate

sub callIterateFunction {
  my ($styString) = @_;
  return callRuntimeFunction('iterateFunction', '\\&' . escapeFunctionName($styString->getValue), $styString);
}

sub callIterateBuiltin {
  my ($styString) = @_;
  return callRuntimeFunction('iterateFunction', '\\&' . escapeBuiltinName($styString->getValue), $styString);
}

### iterate

sub callReverseFunction {
  my ($styString) = @_;
  return callRuntimeFunction('reverseFunction', '\\&' . escapeFunctionName($styString->getValue), $styString);
}

sub callReverseBuiltin {
  my ($styString) = @_;
  return callRuntimeFunction('reverseFunction', '\\&' . escapeBuiltinName($styString->getValue), $styString);
}

### block

sub callPushFunctionStart {
  return 'pushFunction($context, ';
}

sub callPushFunctionEnd {
  my ($styString) = @_;
  return ', ' . $styString->stringify . '); ';
}

sub callPopValue {
  my ($context) = @_;
  return callRuntimeFunction('popValue');
}
### variables

sub callPushGlobalString {
  my ($styString) = @_;
  return callRuntimeFunction('pushGlobalString', escapeString($styString->getValue), $styString);
}

sub callPushGlobalInteger {
  my ($styString) = @_;
  return callRuntimeFunction('pushGlobalInteger', escapeString($styString->getValue), $styString);
}

sub callPushEntryField {
  my ($styString) = @_;
  return callRuntimeFunction('pushEntryField', escapeString($styString->getValue), $styString);
}

sub callPushEntryString {
  my ($styString) = @_;
  return callRuntimeFunction('pushEntryString', escapeString($styString->getValue), $styString);
}

sub callPushEntryInteger {
  my ($styString) = @_;
  return callRuntimeFunction('pushEntryInteger', escapeString($styString->getValue), $styString);
}

sub callCallFunction {
  my ($styString) = @_;
  return callRuntimeFunction(escapeFunctionName($styString->getValue), $styString);
}

sub callCallBuiltin {
  my ($styString) = @_;
  return callRuntimeFunction(escapeBuiltinName($styString->getValue), $styString);
}

### references

sub callLookupGlobalString {
  my ($styString) = @_;
  return callRuntimeFunction('lookupGlobalString', escapeString($styString->getValue), $styString);
}

sub callLookupGlobalInteger {
  my ($styString) = @_;
  return callRuntimeFunction('lookupGlobalInteger', escapeString($styString->getValue), $styString);
}

sub callLookupEntryField {
  my ($styString) = @_;
  return callRuntimeFunction('lookupEntryField', escapeString($styString->getValue), $styString);
}

sub callLookupEntryString {
  my ($styString) = @_;
  return callRuntimeFunction('lookupEntryString', escapeString($styString->getValue), $styString);
}

sub callLookupEntryInteger {
  my ($styString) = @_;
  return callRuntimeFunction('lookupEntryInteger', escapeString($styString->getValue), $styString);
}

sub callLookupFunction {
  my ($styString) = @_;
  return callRuntimeFunction('lookupFunction', '\\&' . escapeFunctionName($styString->getValue), $styString);
}

sub callLookupBuiltin {
  my ($styString) = @_;
  return callRuntimeFunction('lookupFunction', '\\&' . escapeBuiltinName($styString->getValue), $styString);
}

### strings + integers

sub callPushString {
  my ($styString) = @_;
  return callRuntimeFunction('pushString', escapeString($styString->getValue), $styString);
}

sub callPushInteger {
  my ($styString) = @_;
  return callRuntimeFunction('pushInteger', $styString->getValue, $styString);
}

#### internal implementation
sub callRuntimeFunction {
  my ($name, @arguments) = @_;
  my @args = map { (ref $_) ? $_->stringify : $_ } @arguments;
  my $call = join(", ", @args);
  return "$name(\$context, " . $call . '); ';
}

1;

