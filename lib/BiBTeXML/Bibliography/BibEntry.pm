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

use base qw(BiBTeXML::Common::Object);
use BiBTeXML::Common::Utils;

use base qw(Exporter);
our @EXPORT = (
  qw( &BibEntry ),
);

sub new {
  my ($class, $type, $tags, $source) = @_;
  return bless {
    type   => $type,     # the type of entry we have (see getType)
    tags   => $tags,     # a list of tags in this BiBFile
    source => $source    # a source referenb
  }, $class;
}

sub BibEntry { BiBTeXML::Bibliography::BibEntry->new(@_); }

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

# evaluates this entry, i.e. normalizes the type
# and evaluates all tags
sub evaluate {
  my ($self, %context) = @_;

  $$self{type}->normalizeValue;

  my @tags = @{ $$self{tags} };
  my $tag;
  foreach $tag (@tags) {
    $tag->evaluate(%context);
  }
}

# turns this BibEntry into a string representing code to create this object
sub stringify {
  my ($self) = @_;
  my ($type) = $self->getType->stringify;
  my @tags = map { $_->stringify; } @{ $self->getTags };
  my $tagStr = '[(' . join(',', @tags) . ')]';

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return 'BibTag(' . $type . ', ' . $tagStr . ", [($sr, $sc, $er, $ec)])";
}

1;
