# /=====================================================================\ #
# |  BibTeXML::Core::BibTag                                             | #
# | Representation for tags inside .bib entries                         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BibTeXML::Core::BibTag;
use strict;
use warnings;
use List::Util qw(reduce);

sub new {
  my ($class, $name, $content, $source) = @_;
  return bless {
    name      => $name,         # name of the tag (may be omitted)
    content   => $content,      # the content of the tag (list, required)
    source    => $source,       # a source
  }, $class;
}

sub getSource {
  my ($self) = @_;
  return $$self{source};
}

sub getName {
  my ($self) = @_;
  return $$self{name};
}

sub getContent {
  my ($self) = @_;
  return $$self{content};
}

# evaluates this BiBTag in place
sub evaluate {
  my ($self, %context) = @_;

  my @content = @{ $self->getContent };

  # if we have no values, return
  return if (scalar @content eq 0);

  # if we have only a single value, evaluate that and return
  if (scalar(@content) eq 1) {
    $content[0]->evaluate(%context);
    return;
  }

  my $contains = reduce {
    my ($l, $r) = @_;
    $l->append($r);
    return $l;
  } @content;

  $$self{content} = [($contains)];
}

sub stringify {
  my ($self)  = @_;
  my ($name)  = $self->getName;
  $name = defined($name) ? $name->stringify : '';
  my @content = map { $_->stringify; } @{ $self->getContent };
  my $contains = '[' . join(',', @content) . ']';

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "BibTag[name=$name, content=$contains, from=$sr:$sc, to=$er:$ec]";
}

sub equals {
    my ($self, $other) = @_;
    $other = ref $other ? $other->stringify : $other;
    return $self->stringify eq $other; 
}

1;
