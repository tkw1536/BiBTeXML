# /=====================================================================\ #
# |  BiBTeXML::Compiler::Utils                                          | #
# | .bst -> perl compiler utilities                                     | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Compiler::Utils;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = (
  qw( &escapeString &escapeName &escapeSource),
  qw( &escapeBuiltinName &escapeFunctionName ),
  qw( &makeIndent ),
  qw( &compileLocation )
);

# encodes a perl string as a literal string passable to eval
sub escapeString {
  my ($value) = @_;
  $value =~ s/\\/\\\\/g;          # escape \ as \\
  $value =~ s/'/\\'/g;            # escape ' as \'
  return '\'' . $value . '\'';    #  surround in single quotes
}

sub escapeSource {
  my ($source) = @_;
  my ($sr, $sc, $er, $ec) = @$source;
  return "[($sr, $sc, $er, $ec)]";
}

# escape the name of a function or variable for use as the name
# of a subrutine in generated perl code
sub escapeName {
  my ($name) = @_;
  my $result = '';
  my ($ord);
  my @chars = split(//, $name);
  foreach my $char (@chars) {
    $ord = ord($char);
    # leave aA-zZ0-9 intact
    if (($ord >= 48 && $ord <= 57) or ($ord >= 65 && $ord <= 90) or ($ord >= 97 && $ord <= 122)) {
      $result .= $char;
    } elsif ($char eq '_') { $result .= '__';
    } elsif ($char eq '.') { $result .= '_o_';
    } elsif ($char eq '$') { $result .= '_S_';
    } elsif ($char eq '>') { $result .= '_gt_';
    } elsif ($char eq '<') { $result .= '_lt_';
    } elsif ($char eq '=') { $result .= '_eq_';
    } elsif ($char eq '+') { $result .= '_pl_';
    } elsif ($char eq '-') { $result .= '_mi_';
    } elsif ($char eq '*') { $result .= '_as_';
    } elsif ($char eq ':') { $result .= '_co_';
    } else {    # escape anything else as _<ascii>_
      $result .= '_' . $ord . '_';
    }
  }
  return $result;
}

sub escapeBuiltinName {
  my ($name) = @_;
  return 'builtin__' . escapeName($name);
}

sub escapeFunctionName {
  my ($name) = @_;
  return 'bst__' . escapeName($name);
}

sub compileLocation {
  my ($str) = @_;
  my ($sr, $sc, $er, $ec) = @{ $str->getSource };
  return "# from=$sr:$sc to=$er:$ec\n";
}

# given a numeric indentation level, returns a string representing the indent
sub makeIndent {
  '  ' x $_[0];
}

1;

