# /=====================================================================\ #
# |  BiBTeXML::Runtime::Entry                                           | #
# | A read BiBTeX Entry                                     | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Entry;
use strict;
use warnings;

use BiBTeXML::Common::Utils;

###
### Read entries
###

### An entry consists of the following values:

sub new {
  my ($class, $context, $entry) = @_;

  # read our type, skip 'string's and 'comment's
  my $type = lc $entry->getType->getValue;
  return undef, undef if $type eq 'string' or $type eq 'comment';

  # read the tags
  my @tags = @{ $entry->getTags };

  # if we have a preamble, return the conent of the preamble
  if ($type eq 'preamble') {
    return undef, ['Missing content for preamble ' . $entry->getLocationString] unless scalar(@tags) eq 1;
    my $preamble = shift(@tags);
    return $preamble->getContent->getValue, [('', 'preamble')];
  }

  # Make sure that we have something
  return undef, ['Missing key for entry ' . $entry->getLocationString] unless scalar(@tags) > 0;

  # make sure that we have a key
  my $key = shift(@tags)->getContent->getValue;
  return undef, ['Expected non-empty key ' . $entry->getLocationString] unless $key;

  my ($tag, $value, $valueKey);
  my %values = ();
  my (@warnings) = ();

  foreach $tag (@tags) {
    $valueKey = $tag->getName;
    $value    = $tag->getContent->getValue;

    # we need a key=value in this tag
    unless (defined($valueKey)) {
      push(@warnings, 'Missing key for value ' . $tag->getContent->getLocationString);
      next;
    }

    $valueKey = lc $valueKey->getValue;

    # if we have a duplicate valye
    if (defined($values{$valueKey})) {
      push(@warnings, 'Duplicate value in entry ' . $key . ': Tag ' . $valueKey . ' already defined. ' . $tag->getContent->getLocationString);
      next;
    }
    $values{$valueKey} = $value;
  }

  my $self = bless {
    # the context corresponding to this entry
    context => $context,

    # - the type, key and values for the entry
    type   => $type,
    key    => $key,
    values => {%values},

    # the variables stored in this entry
    variables => {}

  }, $class;

  # if we have warnings, return them
  return $self, [@warnings] if scalar(@warnings) > 0;

  # else just return self
  return $self, undef;
}

# gets the value of a given variable
# get a variable (type, value, source) or undef if it doesn't exist
sub getVariable {
  my ($self, $name) = @_;

  # lookup the type and return their value
  my $type = $$self{context}{variableTypes}{$name};
  return undef unless defined($type) && startsWith($type, 'ENTRY_');

  # If we have an entry field
  # we need to take special care of where it comes from
  # TODO: Do we need to support integers here?
  if ($type eq 'ENTRY_FIELD') {
    my $field = $$self{values}{ lc $name };

    return 'STRING', [$field], [[($$self{key}, lc $name)]] if defined($field);
    return 'MISSING', undef, [($$self{key}, lc $name)];
  }

  my $value = $$self{variables}{$name};
  return 'UNSET', undef, undef unless defined($value);

  # else we can just push from our own internal value stack
  # we duplicate here, where needed
  my ($t, $v, $s) = @{$value};
  $v = [@{$v}] if ref($v) && ref($v) eq 'ARRAY';
  $s = [@{$s}] if ref($s) && ref($s) eq 'ARRAY';
  return ($t, $v, $s);
}

# set a variable (type, value, source)
# returns 0 if ok, 1 if it doesn't exist,  2 if an invalid context, 3 if read-only
sub setVariable {
  my ($self, $name, $value) = @_;

  # if the variable does not exist, return nothing
  my $type = $$self{context}{variableTypes}{$name};
  return 1 unless defined($type);

  # we can't assign anything global here
  return 2 if (
    $type eq 'GLOBAL_STRING'  or
    $type eq 'GLOBAL_INTEGER' or
    $type eq 'FUNCTION'
  );

  # we can't assign entry fields, they're read only
  return 3 if $type eq 'ENTRY_FIELD';

  # and assign the value
  $$self{variables}{$name} = $value;
  return 0;
}

1;
