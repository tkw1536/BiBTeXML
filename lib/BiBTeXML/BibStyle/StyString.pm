# /=====================================================================\ #
# |  BiBTeXML::BibStyle::StyString                                      | #
# | Representations for strings with source refs to a .bst file         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::BibStyle::StyString;
use strict;
use warnings;

sub new {
  my ($class, $kind, $value, $source) = @_;
  return bless {
    kind => $kind || '',    # the kind of string we have (see getKind)
    value  => $value,       # the value in this string (see getValue)
    source => $source,      # the source position (see getSource)
  }, $class;
}

# get the kind this StyString represents. One of:
#   ''            (other)
#   'NUMBER'      (a literal number)
#   'QUOTE'       (a literal string)
#   'LITERAL'     (any unquoted value)
#   'REFERENCE'   (a reference to a function or variable)
#   'BLOCK'       (a {} enclosed list of other StyStrings)
sub getKind {
  my ($self) = @_;
  return $$self{kind};
}

# get the value of this StyString
# why
sub getValue {
  my ($self) = @_;
  return $$self{value};
}

sub getSource {
  my ($self) = @_;
  return $$self{source};
}

sub stringify {
  my ($self) = @_;
  my ($kind) = $$self{kind};

  my $value;
  if ($kind eq 'BLOCK') {
    my @content = map { $_->stringify; } @{ $$self{value} };
    $value = '[' . join(', ', @content) . ']';
  } elsif ($kind eq 'NUMBER') {
    $value = $$self{value};
  } else {
    $value = '"' . $$self{value} . '"';
  }

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "StyString[$kind, $value, from=$sr:$sc, to=$er:$ec]";
}

sub equals {
  my ($self, $other) = @_;
  $other = ref $other ? $other->stringify : $other;
  return $self->stringify eq $other;
}

1;
