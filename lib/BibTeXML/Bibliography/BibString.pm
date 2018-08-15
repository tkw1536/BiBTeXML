# /=====================================================================\ #
# |  BibTeXML::Bibliography::BibString                                  | #
# | Representations for files with source refs to a .bib file           | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BibTeXML::Bibliography::BibString;
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

# known kinds = '', 'LITERAL', 'BRACE', 'QUOTE'
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

sub evaluate {
  my ($self, %context) = @_;

  # if we have a literal, we need to substitute values
  if ($$self{kind} eq 'LITERAL') {
    $$self{kind}  = '';
    $$self{value} = $context{ $$self{value} };
  }
}

sub append {
  my ($self, $other, %context) = @_;

  # evaluate self
  $self->evaluate(%context);

  # evaluate other
  $other->evaluate(%context);

  # update values
  $$self{kind}  = '';
  $$self{value} = $self->getValue . $other->getValue;
  # TODO: This concatinates {} as well, which isn't allowed

  my ($sr, $sc) = @{ $self->getSource };
  my ($a, $b, $er, $ec) = @{ $other->getSource };

  $$self{source} = [($sr, $sc, $er, $ec)];
}

sub stringify {
  my ($self)  = @_;
  my ($kind)  = $$self{kind};
  my ($value) = $$self{value};

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "BibString[$kind, \"$value\", from=$sr:$sc, to=$er:$ec]";
}

sub equals {
    my ($self, $other) = @_;
    $other = ref $other ? $other->stringify : $other;
    return $self->stringify eq $other; 
}

1;
