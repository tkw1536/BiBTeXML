# /=====================================================================\ #
# |  BiBTeXML::Runtime::Context                                         | #
# | The entire context of a runtime                                     | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Context;
use strict;
use warnings;

use BiBTeXML::Bibliography qw(readFile);
use BiBTeXML::Common::Utils;

use BiBTeXML::Runtime::Entry;

###
### The Context
###

### The context, a.k.a. state, contains all values of the runtime system, with the exception of builtins.
### It consists of the following items:

sub new {
  my ($class) = @_;
  return bless {
    ### - the stack (split into three parts, see below)
    typeStack => [], valueStack => [], sourceStack => [],

    ### - a set of macros
    macros => {},

    ### - a set of global string variables (with three values each, as in the stack)
    ### along with the types ('GLOBAL_STRING', 'ENTRY_STRING', 'GLOBAL_INTEGER', 'ENTRY_INTEGER', 'ENTRY_FIELD');
    variables     => {},
    variableTypes => {},

    ### - a list of read entries, and the current entry (if any)
    entries => undef,
    entry   => undef,

    ### - an output buffer (split into an array of string, and an array of references)
    outputString   => [], outputSource   => [],
    preambleString => [], preambleSource => [],

  }, $class;
}

###
### Low-level stack access
###

### The runtime stack internally consists of three stacks, which are kept in sync.
### - the 'typeStack' contains the types of objects
### - the 'valueStack' contains the actual objects
### - the 'sourceStack' contains the source references of objects
### This allows for quick type inspection without having to deconstruct anything.

### The following types are defined:

### 0. 'UNSET' - if a variable has not been set
### 1. 'MISSING' - a missing value of a field (TODO: perhaps also an uninititialized constant)
### 2. 'STRING' - a simple string
### 3. 'INTEGER' -- an integer
### 4. 'FUNCTION' -- a function
### 5. 'REFERENCE' -- a reference to a variable or function on the stack. Starts with 'GLOBAL_' or 'ENTRY_'.

### These have the corresponding values:

### 0. 'UNSET' -- undef
### 1. 'MISSING' -- undef
### 2. 'STRING' -- a tuple of strings
### 3. 'INTEGER' -- a single integer
### 4. 'FUNCTION' -- the function reference
### 5. 'REFERENCE' -- a pair (variable type, reference) of the type of variable being referenced and the actual value being referened

### The corresponding source references are:
### 0. 'UNSET' -- undef
### 1. 'MISSING' -- a tuple(key, field) this value comes from
### 2. 'STRING' -- a tuple (key, field) or undef for each string
### 3. 'INTEGER' -- a tuple (key, field) or undef, when joining take the first one
### 4. 'FUNCTION' -- undef
### 5. 'REFERENCE' -- undef

# return the length of the stack
sub stackLength {
  my ($self) = @_;
  return scalar(@{ $$self{typeStack} });
}

# pop the stack
# returns the value or undef, undef, undef
sub popStack {
  my ($self) = @_;
  return undef, undef, undef unless scalar(@{ $$self{typeStack} }) > 0;
  return (
    pop(@{ $$self{typeStack} }),
    pop(@{ $$self{valueStack} }),
    pop(@{ $$self{sourceStack} })
  );
}

# peek at the position index from the back. index is 1 based.
# returns the value looked up or 0
sub peekStack {
  my ($self, $index) = @_;
  return undef, undef, undef unless scalar(@{ $$self{typeStack} }) >= $index;
  return (
    $$self{typeStack}[-$index],
    $$self{valueStack}[-$index],
    $$self{sourceStack}[-$index]
  );
}

# pops an item from the stack
# returns 1
sub pushStack {
  my ($self, $type, $value, $source) = @_;
  push(@{ $$self{typeStack} },   $type);
  push(@{ $$self{valueStack} },  $value);
  push(@{ $$self{sourceStack} }, $source);
  return 1;
}

# sets a specific value on the stack
# return 1 iff successfull
sub putStack {
  my ($self, $index, $type, $value, $source) = @_;
  return 0 unless scalar(@{ $$self{typeStack} }) >= $index;
  $$self{typeStack}[-$index]   = $type if defined($type);
  $$self{valueStack}[-$index]  = $value;
  $$self{sourceStack}[-$index] = $source;
  return 1;
}

# pushes a string constant onto the stack
sub pushString {
  my ($self, $string) = @_;
  push(@{ $$self{typeStack} }, 'STRING');
  push(@{ $$self{valueStack} },  [$string]);
  push(@{ $$self{sourceStack} }, [undef]);
  return 1;
}

# pushes an integer constant onto the stack
sub pushInteger {
  my ($self, $integer) = @_;
  push(@{ $$self{typeStack} },   'INTEGER');
  push(@{ $$self{valueStack} },  $integer);
  push(@{ $$self{sourceStack} }, undef);
  return 1;
}

# empties the stack
sub emptyStack {
  my ($self) = @_;
  $$self{typeStack}   = [];
  $$self{valueStack}  = [];
  $$self{sourceStack} = [];
}

# duplicate the head of the stack
sub duplicateStack {
  my ($self) = @_;
  return 0 unless scalar(@{ $$self{typeStack} }) > 0;

  # duplicate the type
  push(@{ $$self{typeStack} }, $$self{typeStack}[-1]);

  # deep-copy the value if needed
  my $value = $$self{valueStack}[-1];
  $value = [@{$value}] if ref $value && ref $value eq "ARRAY";
  push(@{ $$self{valueStack} }, $value);

  # deep-copy the source if needed
  my $source = $$self{sourceStack}[-1];
  $source = [@{$source}] if ref $source && ref $source eq "ARRAY";
  push(@{ $$self{sourceStack} }, $source);

  return 1;
}

###
### MACROS
###

# sets a macro of the given name
# returns 1
sub setMacro {
  my ($self, $name, $value) = @_;
  $$self{macros}{ lc $name } = $value;
  return 1;
}

# gets a macro
sub getMacro {
  my ($self, $name) = @_;
  return $$self{macros}{ lc $name };
}

# checks if a macro of the given name exists
sub hasMacro {
  my ($self, $name, $value) = @_;
  return defined($$self{macros}{ lc $name });
}

###
### VARIABLES
###

sub hasVariable {
  my ($self, $name, $type) = @_;
  if (defined($$self{variableTypes}{$name})) {
    if (defined($type)) {
      return ($$self{variableTypes} eq $type) ? 1 : 0;
    }
    return 1;
  }
  return 0;
}

# defines a new variable for use in the stack
# return 1 if ok, 0 if already defined
sub defineVariable {
  my ($self, $name, $type) = @_;
  return 0 if defined($$self{variableTypes}{$name});

  # store the type and set initial value if global
  $$self{variableTypes}{$name} = $type;
  unless (startsWith($type, 'ENTRY_')) {
    $$self{variables}{$name} = [('UNSET', undef, undef)];
  }

  return 1;
}

# get a variable (type, value, source) or undef if it doesn't exist
sub getVariable {
  my ($self, $name) = @_;

  # if the variable does not exist, return nothing
  my $type = $$self{variableTypes}{$name};
  return (undef, undef, undef) unless defined($type);

  # we need to look up inside the current entry
  if (
    $type eq 'ENTRY_FIELD'  or
    $type eq 'ENTRY_STRING' or
    $type eq 'ENTRY_INTEGER'
  ) {
    my $entry = $$self{entry};
    return ('UNSET', undef, undef) unless defined($entry);
    return $entry->getVariable($name);

    # we have a global variable, so take it from out own state
    # note: we need to duplicate the value and source, because they may be modified by future calls
  } else {
    my ($t, $v, $s) = @{ $$self{variables}{$name} };
    $v = [@{$v}] if ref($v) && ref($v) eq 'ARRAY';
    $s = [@{$s}] if ref($s) && ref($s) eq 'ARRAY';
    return ($t, $v, $s);
  }
}

# set a variable (type, value, source)
# returns 0 if ok, 1 if it doesn't exist,  2 if an invalid context, 3 if read-only, 4 if unknown type
sub setVariable {
  my ($self, $name, $value) = @_;

  # if the variable does not exist, return nothing
  my $type = $$self{variableTypes}{$name};
  return 1 unless defined($type);

  # we need to look up inside the current entry
  if (
    $type eq 'ENTRY_FIELD'  or
    $type eq 'ENTRY_STRING' or
    $type eq 'ENTRY_INTEGER'
  ) {
    my $entry = $$self{entry};
    return 2 unless defined($entry);
    return $entry->setVariable($name, $value);
    # we have a global variable, so take it from our stack
  } elsif (
    $type eq 'GLOBAL_STRING'  or
    $type eq 'GLOBAL_INTEGER' or
    $type eq 'FUNCTION'
  ) {
    # else assign the value
    $$self{variables}{$name} = $value;

    # and return
    return 0;

    # I don't know the type
  } else {
    return 4;
  }
}

# defines and assigns a variable
# returns 0 if ok, 1 if it already exists, 2 if an invalid context, 3 if read-only, 4 if unknown type
sub assignVariable {
  my ($self, $name, $type, $value) = @_;

  # define the variable
  my $def = $self->defineVariable($name, $type);
  return 1 unless $def eq 1;

  return $self->setVariable($name, $value);
}

###
### ENTRIES
###

# returns the entries loaded by this context, or undef if none
sub getEntries {
  my ($self) = @_;
  return $$self{entries};
}

# reads entries from a given reader
# returns (0, warnings) if ok, (1, undef) if entries were already read and (2, error) if something went wrong while reading
# always closes all readers, if status != 1.
sub readEntries {
  my ($self, @readers) = @_;

  return 1, undef if defined($$self{entries});

  my @entries   = ();
  my @warnings  = ();
  my @locations = ();

  my ($name, $reader, $parse, $parseError, $entry, $warning, $location);
  while (defined($name = shift(@readers))) {
    $reader = shift(@readers);
    ($parse, $parseError) = readFile($reader, 1, %{ $$self{macros} });
    $reader->finalize;

    # if we have a parse error, close all the other readers
    if (scalar(@{$parseError}) > 0) {
      foreach $reader (@readers) {
        $reader->finalize;
      }
      return 2, $parseError;
    }

    # iterate over all the entries
    foreach $entry (@{$parse}) {
      ($entry, $warning, $location) = BiBTeXML::Runtime::Entry->new($name, $self, $entry);
      if (defined($entry)) {
        # if we got back a ref, it's a proper entry
        if (ref $entry) {
          push(@entries, $entry) if defined($entry) && ref $entry;
          # else it is a preamble, and it's source
        } else {
          push(@{ $$self{preambleString} }, $entry);
          push(@{ $$self{preambleSource} }, $warning);
          next;
        }
      }
      push(@warnings,  @$warning)  if defined($warning);
      push(@locations, @$location) if defined($location);
    }
  }

  # resolve all the cross references
  my $eref = [@entries];
  foreach $entry (@entries) {
    ($warning, $location) = $entry->resolveCrossReferences($eref);
  }

  # TODO: Filter entries to only include a sub-set

  # send all the references
  $$self{entries} = [@entries];

  return 0, [@warnings], [@locations];
}

sub getPreamble {
  my ($self) = @_;
  return $$self{preambleString}, $$self{preambleSource};
}

# sort entries in-place using a comparison function
# return 1 iff entriues have been sorted
sub sortEntries {
  my ($self, $comp) = @_;

  $$self{entries} = [sort { &{$comp}($a, $b) } @{ $$self{entries} }];
  return 1;
}

# sets the current entry
sub setEntry {
  my ($self, $entry) = @_;
  $$self{entry} = $entry;
}

# gets the current entry (if any)
sub getEntry {
  my ($self) = @_;
  return $$self{entry};
}

# leave the current entry (if any)
sub leaveEntry {
  my ($self) = @_;
  $$self{entry} = undef;
}

1;
