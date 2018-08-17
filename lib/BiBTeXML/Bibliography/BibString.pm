# /=====================================================================\ #
# |  BiBTeXML::Bibliography::BibString                                  | #
# | Representations for strings with source refs to a .bib file         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Bibliography::BibString;
use strict;
use warnings;

use base qw(BiBTeXML::Common::Object);

sub new {
  my ($class, $kind, $value, $source) = @_;
  return bless {
    kind   => $kind || '',    # the kind of string we have (see getKind)
    value  => $value,         # the value in this string (see getValue)
    source => $source,        # the source position (see getSource)
  }, $class;
}

# return a copy of this entry
sub copy {
  my ($self) = @_;

  # we need to deep-copy the source
  my ($sr, $sc, $er, $ec) = @{ $$self{source} };
  return new($$self{kind}, $$self{value}, [($sr, $sc, $er, $ec)]);
}

# get the kind this BibString represents. One of:
#   ''          (other)
#   'LITERAL'   (an unquoted literal from the source file)
#   'BRACE'     (a braced string from the source file)
#   'QUOTE'     (a quoted string from the source file)
#   'EVALUATED' (anything that has been evaluated or concatinated)
sub getKind {
  my ($self) = @_;
  return $$self{kind};
}

# get the value of this BiBString, a normal string
sub getValue {
  my ($self) = @_;
  return $$self{value};
}

# normalizes the value of this BiBString
# i.e. turns it into lower-case
sub normalizeValue {
  my ($self) = @_;
  $$self{value} = lc($$self{value});
}

# evaluate this BibString inside of a context
# i.e. if it is a literal read the value from the context
# returns 0 iff evaluation failed, and 1 otherwise.
sub evaluate {
  my ($self, %context) = @_;

  if ($$self{kind} eq 'LITERAL') {
    $$self{kind} = 'EVALUATED';
    my $value = $context{ lc($$self{value}) };
    return 0 unless defined($value);
    $$self{value} = $value->getValue;
  }

  return 1;
}

# appends the value of another BiBString to this one
# and updates the source ref accordingly
# DOES NOT do any type checking what-so-ever
sub append {
  my ($self, $other) = @_;

  # append the value to our own class
  $$self{kind} = 'EVALUATED';
  $$self{value} .= $other->getValue;

  # update the source reference
  my ($sr, $sc) = @{ $$self{source} };
  my ($a, $b, $er, $ec) = @{ $other->getSource };
  $$self{source} = [($sr, $sc, $er, $ec)];
}

# turns this BibString into a string for human-readable presentation
sub stringify {
  my ($self)  = @_;
  my ($kind)  = $$self{kind};
  my ($value) = $$self{value};

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "BibString[$kind, \"$value\", from=$sr:$sc, to=$er:$ec]";
}

1;
