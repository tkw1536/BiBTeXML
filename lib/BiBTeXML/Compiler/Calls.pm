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
  qw(&callLookupBlockStart &callLookupBlockEnd),
  qw(&callPushGlobalString &callPushGlobalInteger &callLookupEntryField &callPushEntryString &callPushEntryInteger &callCallFunction &callCallBuiltin),
  qw(&callLookupGlobalString &callLookupGlobalInteger &callLookupEntryString &callLookupEntryInteger &callLookupFunction &callLookupBuiltin),
  qw(&callPushString &callPushArgument),
);

### block

sub callLookupBlockStart {
  return 'lookupFunction($context, ';
}

sub callLookupBlockEnd {
  my ($styString) = @_;
  return ', ' . $styString->stringify . '); ';
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

sub callLookupEntryField {
  my ($styString) = @_;
  return callRuntimeFunction('lookupEntryField', escapeString($styString->getValue), $styString);
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
  return callRuntimeFunction(escapeFunctionName($styString->getValue), undef, $styString);
}

sub callCallBuiltin {
  my ($styString) = @_;
  return callRuntimeFunction(escapeBuiltinName($styString->getValue), undef, $styString);
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

### strings + arguments

sub callPushString {
  my ($styString) = @_;
  return callRuntimeFunction('pushString', escapeString($styString->getValue), $styString);
}

sub callPushArgument {
  my ($styString) = @_;
  return callRuntimeFunction('pushArgument', '$arg' . $styString->getValue, $styString);
}

#### internal implementation
sub callRuntimeFunction {
  my ($name, $argument, $styString) = @_;
  return "$name(\$context, " . (defined($argument) ? "$argument, " : '') . $styString->stringify . '); ';
}

1;

