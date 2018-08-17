# /=====================================================================\ #
# |  BiBTeXML::BibStyle::StyCommand                                     | #
# | Representations for commands with source refs to a .bst file        | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::BibStyle::StyCommand;
use strict;
use warnings;

use base qw(BiBTeXML::Common::Object);

sub new {
  my ($class, $name, $arguments, $source) = @_;
  return bless {
    name      => $name || '',    # the name of the command (see getName)
    arguments => $arguments,     # the arguments to the command (see getArguments)
    source    => $source,        # the source position of the command (see getSource)
  }, $class;
}

# the name of the command. Should be a STYString of type Literal.
sub getName {
  my ($self) = @_;
  return $$self{name};
}

# the arguments of this command. Should be StyStrings of type LITERAL.
sub getArguments {
  my ($self) = @_;
  return $$self{arguments};
}

# turns this StyCommand into a string for human-readable presentation
sub stringify {
  my ($self) = @_;
  my ($name) = $$self{name}->stringify;

  my @arguments = map { $_->stringify; } @{ $$self{arguments} };
  my $value = '[' . join(', ', @arguments) . ']';

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return "StyCommand[$name, $value, from=$sr:$sc, to=$er:$ec]";
}

1;
