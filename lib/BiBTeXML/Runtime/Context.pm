# /=====================================================================\ #
# |  BiBTeXML::Runtime::Context                                         | #
# | The entire context of a runtime                                     | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Context;

use BiBTeXML::Common::Utils;

###
### The Context
###

### The context, a.k.a. state, contains all values of the runtime system, with the exception of builtins.
### It consists of the following items:

sub new {
  my ($class) = @_;
  return bless {
    ### - the stack (split into three parts, see below)
    typeStack => {}, valueStack => {}, sourceStack => {},

    ### - a set of macros
    macros => {},

    ### - a set of global string variables (with three values each, as in the stack)
    variables      => {},
    variable_types => {},

    ### - a list of read entries, and the current entry (if any)
    entries => [],
    entry   => undef,

    ### - an output buffer (split into an array of string, and an array of references)
    outputBufferStrings => [], outputBufferSources => [],
  }, $class;
}

###
### Low-level stack access
###

# return the length of the stack
sub stackLength {
  my ($self) = @_;
  return scalar(@{ $self{typeStack} });
}

# pop the stack
# returns the value or undef, undef, undef
sub popStack {
  my ($self) = @_;
  return undef, undef, undef unless scalar(@{ $self{typeStack} }) > 0;
  return (
    pop(@{ $self{typeStack} }),
    pop(@{ $self{valueStack} }),
    pop(@{ $self{sourceStack} })
  );
}

# peek at the position index from the back. index is 1 based.
# returns the value looked up or 0
sub peekStack {
  my ($self, $index) = @_;
  return undef, undef, undef unless scalar(@{ $self{typeStack} }) >= $index;
  return (
    $self{typeStack}[-$index],
    $self{valueStack}[-$index],
    $self{sourceStack}[-$index]
  );
}

# pops an item from the stack
# returns 1
sub pushStack {
  my ($self, $type, $value, $source) = @_;
  push(@{ $self{typeStack} },   $type);
  push(@{ $self{valueStack} },  $type);
  push(@{ $self{sourceStack} }, $type);
  return 1;
}

# sets a specific value on the stack
# return 1 iff successfull
sub putStack {
  my ($self, $index, $type, $value, $source) = @_;
  return 0 unless scalar(@{ $self{typeStack} }) >= $index;
  $self{typeStack}[-$index]   = $type if defined($type);
  $self{valueStack}[-$index]  = $value;
  $self{sourceStack}[-$index] = $source;
  return 1;
}

# pushes a string constant onto the stack
sub pushString {
  my ($self, $string) = @_;
  push(@{ $self{typeStack} }, 'STRING');
  push(@{ $self{valueStack} },  [$string]);
  push(@{ $self{sourceStack} }, [undef]);
  return 1;
}

# pushes an integer constant onto the stack
sub pushInteger {
  my ($self, $integer) = @_;
  push(@{ $self{typeStack} },   'INTEGER');
  push(@{ $self{valueStack} },  $integer);
  push(@{ $self{sourceStack} }, undef);
  return 1;
}

# empties the stack
sub emptyStack {
  my ($self) = @_;
  $self{typeStack}   = [];
  $self{valueStack}  = [];
  $self{sourceStack} = [];
}

# duplicate the head of the stack
sub duplicateStack {
  my ($self) = @_;
  return 0 unless scalar(@{ $self{typeStack} }) > 0;

  # duplicate the type
  push(@{ $self{typeStack} }, $self{typeStack}[-1]);

  # deep-copy the value if needed
  my $value = $self{valueStack}[-1];
  $value = [@{$value}] if ref $value && ref $value eq "ARRAY";
  push(@{ $self{valueStack} }, $value);

  # deep-copy the source if needed
  my $source = $self{sourceStack}[-1];
  $source = [@{$source}] if ref $source && $source eq "ARRAY";
  push(@{ $self{sourceStack} }, $source);

  return 1;
}

###
### MACROS
###

# sets a macro of the given name
# returns 1
sub setMacro {
  my ($self, $name, $value) = @_;
  $self{macros}{ lc $name } = $value;
  return 1;
}

# gets a macro
sub getMacro {
  my ($self, $name) = @_;
  return $self{macros}{ lc $name };
}

# checks if a macro of the given name exists
sub hasMacro {
  my ($self, $name, $value) = @_;
  return defined($self{macros}{ lc $name });
}

###
### VARIABLES
###

# defines a new variable for use in the stack
# return 1 if ok, 0 if already defined
sub defineVariable {
  my ($self, $name, $type) = @_;
  return 0 if defined($self{variableTypes}{$name});

  # store the type and set initial value if global
  $self{variableTypes}{$name} = $type;
  unless (startsWith($type, 'ENTRY_')) {
    $self{variables}{$name} = [('UNSET', undef, undef)];
  }

  return 1;
}

# get a variable (type, value, source) or undef if it doesn't exist
sub getVariable {
  my ($self, $name) = @_;

  # if the variable does not exist, return nothing
  my $type = $self{variableTypes}{$name};
  return (undef, undef, undef) unless defined($type);

  # we need to look up inside the current entry
  if (startsWith($type, 'ENTRY_')) {
    my $entry = $self{entry};
    return ('UNSET', undef, undef) unless defined($entry);
    return $entry->getVariable($name);

    # we have a global variable, so take it from our stack
  } else {
    return @{ $self{variables}{$name} };
  }
}

# set a variable (type, value, source)
# returns 0 if ok, 1 if it doesn't exist and 2 if in invalid context
sub setVariable {
  my ($self, $name, $value) = @_;

  # if the variable does not exist, return nothing
  my $type = $self{variableTypes}{$name};
  return 1 unless defined($type);

  # we need to look up inside the current entry
  if (startsWith($type, 'ENTRY_')) {
    my $entry = $self{entry};
    return 2 unless defined($entry);
    return $entry->setVariable($name, $value);

    # we have a global variable, so take it from our stack
  } else {
    $self{variables}{$name} = $value;
    return 0;
  }
}

###
### The Stack Values
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
### 4. 'REFERENCE' -- a reference to a variable or function on the stack. Starts with 'GLOBAL_' or 'ENTRY_'.

### These have the corresponding values:

### 0. 'UNSET' -- undef
### 1. 'MISSING' -- undef
### 2. 'STRING' -- a tuple of strings
### 3. 'INTEGER' -- a single integer
### 4. 'REFERENCE' -- a pair (variable type, reference) of the type of variable being referenced and the actual value being referened

### The corresponding source references are:
### 0. 'UNSET' -- undef
### 1. 'MISSING' -- a tuple('BIB', key, field) this value comes from
### 2. 'STRING' -- a tuple ('BIB', key, field) or undef for each string
### 3. 'INTEGER' -- a tuple ('BIB', key, field) or undef, when joining take the first one
### 4. 'REFERENCE' -- undef

###
### Putting values onto the stack
###
1;
