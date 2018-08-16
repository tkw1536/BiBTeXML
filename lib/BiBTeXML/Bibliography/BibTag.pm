# /=====================================================================\ #
# |  BiBTeXML::Bibliography::BibTag                                     | #
# | Representation for tags inside .bib entries                         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Bibliography::BibTag;
use strict;
use warnings;
use List::Util qw(reduce);

sub new {
  my ($class, $name, $content, $source) = @_;
  return bless {
    name    => $name,       # name of this tag (may be omitted)
    content => $content,    # content of this tag (see getContent)
    source  => $source,     # the source position (see getSource)
  }, $class;
}

# get the source position of this tag
# a quadruple ($startRow, $startColumn, $endRow, $endColumn)
# row-indexes are one-based, column-indexes zero-based
# the start position is inclusive, the end position is not
# never includes any whitespace in positioning
sub getSource {
  my ($self) = @_;
  return $$self{source};
}

# the name of this literal
sub getName {
  my ($self) = @_;
  return $$self{name};
}

# gets the content of this BiBTag, i.e. either a list of values
# or a single value. 
sub getContent {
  my ($self) = @_;
  return $$self{content};
}

# evaluates the content of this BiBTag
# FAILS if this Tag is already evaluated
# returns a list of items which have failed to evaluate
sub evaluate {
  my ($self, %context) = @_;

  my @failed = ();

  # if we have a name, we need to normalize it
  $$self{name}->normalizeValue if defined($$self{name});

  # we need to expand the value and iterate over it
  my @content = @{ $$self{content} };
  return unless scalar(@content) > 0;

  my $item = shift(@content);
  push(@failed, $item->copy) unless $item->evaluate(%context);

  # evaluate and append each content item
  # from the ones that we have
  # DOES NOT DO ANY TYPE CHECKING
  my $cont;
  foreach $cont (@content){
    push(@failed, $cont) unless $cont->evaluate(%context);
    $item->append($cont);
  }
  
  # and set the new content
  $$self{content} = $item;

  return @failed;
}

# turns this BiBTag into a string for human-readable presentation
sub stringify {
  my ($self) = @_;
  my ($name) = $self->getName;
  $name = defined($name) ? $name->stringify : '';

  my $content = $self->getContent;
  if(ref $content eq 'ARRAY'){
    my @scontent = map { $_->stringify; } @{ $self->getContent };
    $content = '[' . join(',', @scontent) . ']';
  } else {
    $content = $content->stringify;
  }

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "BibTag[name=$name, content=$content, from=$sr:$sc, to=$er:$ec]";
}

# checks if this BiBTag equals another BiBTag
sub equals {
  my ($self, $other) = @_;
  $other = ref $other ? $other->stringify : $other;
  return $self->stringify eq $other;
}

1;
