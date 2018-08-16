# /=====================================================================\ #
# |  BiBTeXML::BibStyle::StyString                                      | #
# | Representations for files with source refs to a .bst file           | #
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
    kind   => $kind || '',
    value  => $value,
    source => $source,       # quadruple
  }, $class;
}

# known kinds = 'LITERAL', 'QUOTE', 'ARGUMENT', 'BLOCK'
sub getKind {
  my ($self) = @_;
  return $$self{kind};
}

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
  if ($kind eq 'BRACE') {
    my @content = map { $_->stringify; } @{ $$self{value} };
    $value = '[' . join(',', @content) . ']';
  } elsif ($kind eq 'ARGUMENT') {
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
