# /=====================================================================\ #
# |  BiBTeXML::Runtime::Functions                                       | #
# | Runtime functions                                                   | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Functions;
use strict;
use warnings;

use BiBTeXML::Runtime::Strings qw(textPurify);

use base qw(Exporter);
our @EXPORT = qw(
  &defineEntryField &defineEntryInteger &defineEntryString &defineGlobalString &defineGlobalInteger &defineGlobalInteger &registerFunctionDefinition &defineMacro
  &readEntries &sortries &iterateFunction &reverseFunction
  &pushString &pushInteger &pushFunction
  &pushFunction &pushGlobalString &pushGlobalInteger &pushEntryField &pushEntryString &pushEntryInteger
  &lookupGlobalString &lookupGlobalInteger &lookupEntryString &lookupEntryInteger &lookupFunction
);

###
### Definining things
###

# defineEntryField($name) -- defines a new entry field
sub defineEntryField {
  my ($context, $config, $name, $styString) = @_;

  $config->log('WARN', "Can not define entry field $name: Already defined", $config->location($styString))
    unless $context->defineVariable($name, 'ENTRY_FIELD');
}

# defineEntryInteger($name) -- defines a new entry integer
sub defineEntryInteger {
  my ($context, $config, $name, $styString) = @_;

  $config->log('WARN', "Can not define entry integer $name: Already defined", $config->location($styString))
    unless $context->defineVariable($name, 'ENTRY_INTEGER');
}

# defineEntryString($name) -- defines a new entry string
sub defineEntryString {
  my ($context, $config, $name, $styString) = @_;

  $config->log('WARN', "Can not define entry string $name: Already defined", $config->location($styString))
    unless $context->defineVariable($name, 'ENTRY_STRING');
}

# defineGlobalString($name) -- defines a new global string
sub defineGlobalString {
  my ($context, $config, $name, $styString) = @_;

  $config->log('WARN', "Can not define global string $name: Already defined", $config->location($styString))
    unless $context->defineVariable($name, 'GLOBAL_STRING');
}

# defineGlobalInteger($name) -- defines a new global integer
sub defineGlobalInteger {
  my ($context, $config, $name, $styString) = @_;

  $config->log('WARN', "Can not define global string $name: Already defined", $config->location($styString))
    unless $context->defineVariable($name, 'GLOBAL_INTEGER');
}

# perl runtime specific: register a function defintion
sub registerFunctionDefinition {
  my ($context, $config, $name, $function, $styString) = @_;
  $config->log('WARN', "Can not define function $name: Already defined", $config->location($styString))
    unless $context->assignVariable($name, 'FUNCTION', ['FUNCTION', $function, undef]) eq 0;
}

# defineMacro($name, $value) -- defines a new macro
sub defineMacro {
  my ($context, $config, $name, $value, $styString) = @_;
  $context->setMacro($name, $value);
}

###
### Reading and iterating over items
###

# readEntries() -- reads all entries from the appropriate .bib file(s)
sub readEntries {
  my ($context, $config, $styString) = @_;
  my @readers = $config->getReaders;

  my ($status, $warnings, $locations) = $context->readEntries(@readers);

  if ($status eq 0) {
    my $warning;
    foreach $warning (@$warnings) {
      $config->log('WARN', $warning, shift(@$locations));    # TODO: Prefix file name here!
    }
  } elsif ($status eq 1) {
    $config->log('WARN', 'Can not read entries: Already read entries', $config->location($styString));
  } else {
    $config->log('ERROR', 'Did not read entries: ' . $warnings, $locations); # TODO: Prefix file name here!
  }
}

# sortEntries() -- sorts (already read) entries
sub sortEntries {
  my ($context, $config, $styString) = @_;
  my %keys = ();

  # find all the entries
  my $entries = $context->getEntries;
  unless (defined($entries)) {
    $config->log('ERROR', 'Can not sort entries:  No entries read yet. ', $config->location($styString));
    return;
  }

  # determine their purified key
  my ($entry, $key);
  foreach $entry (@$entries) {

    # get the sort.key$ variable
    ($key) = $entry->getVariable('sort.key$');
    $key = [''] unless defined($key);    # iff it is undefined
    $key = join('', @$key);

    # and purify it
    $keys{ $entry->getKey } = textPurify($key);
  }

  # sort entries using the purified sorting key
  $context->sortEntries(sub {
      my ($entryA, $entryB) = @_;
      return $keys{ $entryA->getKey } cmp $keys{ $entryB->getKey };
  });
}

# iterateFunction($function) -- iterates a function over all entries
sub iterateFunction {
  my ($context, $config, $function, $styString) = @_;
  my $entries = $context->getEntries;

  unless (defined($entries)) {
    $config->log('WARN', 'Can not iterate entries: No entries have been read', $config->location($styString));
  } else {
    my $entry;
    foreach $entry (@$entries) {
      $context->setEntry($entry);
      &{$function}($context, $config);
    }
    $context->leaveEntry;
  }

}

# reverseFunction($function) -- iterates a function (or builtin) over all (read) entries in reverse
sub reverseFunction {
  my ($context, $config, $function, $styString) = @_;
  my $entries = $context->getEntries;

  unless (defined($entries)) {
    $config->log('WARN', 'Can not iterate entries: No entries have been read. ', $config->location($styString));
  } else {
    my $entry;
    foreach $entry (reverse(@$entries)) {
      $context->setEntry($entry);
      &{$function}($context, $config);
    }
    $context->leaveEntry;
  }
}

###
### Pushing constants onto the stack
###

# pushString($string) -- pushes a string onto the stack
sub pushString {
  my ($context, $config, $string, $styString) = @_;
  $context->pushString($string);
}

# pushInteger($integer) -- pushes an integer onto the stack
sub pushInteger {
  my ($context, $config, $integer, $styString) = @_;
  $context->pushInteger($integer);
}

###
### Pushing references to things onto the stack
###

# pushFunction($block) -- pushes a function (i.e. inline block) onto the stack
sub pushFunction {
  my ($context, $config, $function,) = @_;
  $context->pushStack('FUNCTION', $function, undef);
}

# pushGlobalString($name) -- pushes a global string onto the stack
sub pushGlobalString {
  my ($context, $config, $name, $sourceRef) = @_;
  $context->pushStack('REFERENCE', [('GLOBAL_STRING', $name)], undef);
}

# pushGlobalInteger($name) -- pushes a global integer onto the stack
sub pushGlobalInteger {
  my ($context, $config, $name, $sourceRef) = @_;
  $context->pushStack('REFERENCE', [('GLOBAL_INTEGER', $name)], undef);
}

# pushEntryField($name) -- pushes an entry field onto the stack
sub pushEntryField {
  my ($context, $config, $name, $sourceRef) = @_;
  $context->pushStack('REFERENCE', [('ENTRY_FIELD', $name)], undef);
}

# pushEntryString($name) -- pushes an entry string onto the stack
sub pushEntryString {
  my ($context, $config, $name, $sourceRef) = @_;
  $context->pushStack('REFERENCE', [('ENTRY_STRING', $name)], undef);
}

# pushEntryInteger($name) -- pushes an entry integer onto the stack
sub pushEntryInteger {
  my ($context, $config, $name, $sourceRef) = @_;
  $context->pushStack('REFERENCE', [('ENTRY_INTEGER', $name)], undef);
}

###
### Pushing values of things onto the stack
###

# lookupGlobalString($name) -- pushes the value of a global string onto the stack
sub lookupGlobalString {
  my ($context, $config, $name, $sourceRef) = @_;
  my ($t, $v, $s) = $context->getVariable($name);
  if (defined($t)) {
    $context->pushStack($t, $v, $s);
  } else {
    $config->log('WARN', "Can not push global string $name: Does not exist. ", $config->location($sourceRef));
  }
}

# lookupGlobalInteger($name) -- pushes the value of a integer onto the stack
sub lookupGlobalInteger {
  my ($context, $config, $name, $sourceRef) = @_;
  my ($t, $v, $s) = $context->getVariable($name);
  if (defined($t)) {
    $context->pushStack($t, $v, $s);
  } else {
    $config->log('WARN', "Can not push global integer $name: Does not exist",);
  }
}

# lookupEntryField($name) -- pushes the value of an entry field onto the stack
sub lookupEntryField {
  my ($context, $config, $name, $sourceRef) = @_;
  my ($t, $v, $s) = $context->getVariable($name);
  if (defined($t)) {
    $context->pushStack($t, $v, $s);
  } else {
    $config->log('WARN', "Can not push entry field $name: Does not exist", $config->location($sourceRef));
  }
}

# lookupEntryString($name) -- pushes the value of an entry string onto the stack
sub lookupEntryString {
  my ($context, $config, $name, $sourceRef) = @_;
  my ($t, $v, $s) = $context->getVariable($name);
  if (defined($t)) {
    $context->pushStack($t, $v, $s);
  } else {
    $config->log('WARN', "Can not push entry string $name: Does not exist", $config->location($sourceRef));
  }
}

# lookupEntryInteger($name) -- pushes the value of an entry integer onto the stack
sub lookupEntryInteger {
  my ($context, $config, $name, $sourceRef) = @_;
  my ($t, $v, $s) = $context->getVariable($name);
  if (defined($t)) {
    $context->pushStack($t, $v, $s);
  } else {
    $config->log('WARN', "Can not push entry integer $name: Does not exist", $config->location($sourceRef));
  }
}

# lookupFunction($function) -- pushes a reference to a given (builtin or bst) function onto the stack
sub lookupFunction {
  my ($context, $config, $function, $sourceRef) = @_;
  $context->pushStack('FUNCTION', $function, undef);
}

1;
