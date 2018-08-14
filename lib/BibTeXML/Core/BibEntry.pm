# /=====================================================================\ #
# |  BibTeXML::Core::BibEntry                                           | #
# | Representation for .bib file entries                                | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BibTeXML::Core::BibEntry;
use strict;
use warnings;

sub new {
  my ($class, $type, $tags, $source) = @_;
  return bless {
    type => $type,    # a bibstring
    tags => $tags,    # a bibstring
    source => $source # an array of tags
  }, $class;
}

sub getType {
  my ($self) = @_;
  return $$self{type};
}

sub getTags {
  my ($self) = @_;
  return $$self{tags};
}

sub getSource {
  my ($self) = @_;
  return $$self{source};
}

sub evaluate {
  my ($self, %context) = @_;

  # TODO: Evaluate
}

sub stringify {
  my ($self)  = @_;
  my ($type)  = $self->getType->stringify;
  my @tags = map { $_->stringify; } @{ $self->getTags };
  my $tagStr = '[' . join(',', @tags) . ']';

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "BibEntry[type=$type, tags=$tagStr, from=$sr:$sc, to=$er:$ec]";
}

sub equals {
    my ($self, $other) = @_;
    $other = ref $other ? $other->stringify : $other;
    return $self->stringify eq $other; 
}

1;