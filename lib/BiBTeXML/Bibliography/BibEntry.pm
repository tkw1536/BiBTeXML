# /=====================================================================\ #
# |  BiBTeXML::Bibliography::BibEntry                                   | #
# | Representation for .bib file entries                                | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Bibliography::BibEntry;
use strict;
use warnings;

sub new {
  my ($class, $type, $tags, $source) = @_;
  return bless {
    type   => $type,     # the type of entry we have (see getType)
    tags   => $tags,     # a list of tags in this BiBFile
    source => $source    # a source referenb
  }, $class;
}

# the type of this entry
# a BibString of type 'LITERAL' (and hence lowercase)
sub getType {
  my ($self) = @_;
  return $$self{type};
}

# a list of BibTag s contained in this entry
sub getTags {
  my ($self) = @_;
  return $$self{tags};
}

# get the source position of this entry
# a quadruple ($startRow, $startColumn, $endRow, $endColumn)
# row-indexes are one-based, column-indexes zero-based
# the start position is inclusive, the end position is not
# never includes any whitespace in positioning
sub getSource {
  my ($self) = @_;
  return $$self{source};
}

# evaluates this entry, i.e. normalizes the type
# and evaluates all tags
sub evaluate {
  my ($self, %context) = @_;

  $$self{type}->normalizeValue;

  my @tags = @{$$self{tags}};
  my $tag;
  foreach $tag (@tags){
    $tag->evaluate(%context);
  }
}

# turns this BibEntry into a string for human-readable presentation
sub stringify {
  my ($self) = @_;
  my ($type) = $self->getType->stringify;
  my @tags = map { $_->stringify; } @{ $self->getTags };
  my $tagStr = '[' . join(',', @tags) . ']';

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "BibEntry[type=$type, tags=$tagStr, from=$sr:$sc, to=$er:$ec]";
}

# checks if this BibEntry equals another BibEntry
sub equals {
  my ($self, $other) = @_;
  $other = ref $other ? $other->stringify : $other;
  return $self->stringify eq $other;
}

1;
