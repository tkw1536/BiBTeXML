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
use BiBTeXML::Common::Utils;

use base qw(Exporter);
our @EXPORT = (
  qw( &StyCommand ),
);

sub new {
  my ($class, $name, $arguments, $source) = @_;
  return bless {
    name      => $name || '',    # the name of the command (see getName)
    arguments => $arguments,     # the arguments to the command (see getArguments)
    source    => $source,        # the source position of the command (see getSource)
  }, $class;
}

sub StyCommand { BiBTeXML::BibStyle::StyCommand->new(@_); }

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

# turns this StyCommand into a string representing code to create this object
sub stringify {
  my ($self) = @_;
  my ($name) = $$self{name}->stringify;

  my @arguments = map { $_->stringify; } @{ $$self{arguments} };
  my $value = '[(' . join(', ', @arguments) . ')]';

  my ($sr, $sc, $er, $ec) = @{ $self->getSource };
  return 'StyCommand(' . $name . ', ' . $value . ", [($sr, $sc, $er, $ec)])";
}

1;
