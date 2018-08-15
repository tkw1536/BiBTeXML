# /=====================================================================\ #
# |  BibTeXML::Common::StreamReader                                     | #
# | A primitive reader for input streams                                | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BibTeXML::Common::StreamReader;
use strict;
use warnings;

use Encode;

sub new {
  my ($class) = @_;
  return bless {
    # input and stuff
    IN => undef, encoding => undef, string => undef, buffer => undef,

    # current line information
    line => '', nchars => 0, colno => 0,
    lineno => 0, at_eof => 0,

    # pushback, contains ($char, $line, $col, $at_eof)
    pushback => undef
  }, $class;
}

# ===================================================================== #
# Open / Close
# ===================================================================== #

# opens a file
sub openFile {
  my ($self, $pathname, $encoding) = @_;
  my $IN;
  if (!-r $pathname) {
    return 0; }
  elsif ((!-z $pathname) && (-B $pathname)) {
    return 0; }
  open($IN, '<', $pathname)
    || return 0;
  $$self{IN}       = $IN;
  $$self{buffer}   = [];
  $$self{encoding} = find_encoding($encoding || 'utf-8');

  # reset the state
  $$self{lineno} = 0;
  $$self{colno}  = 0;
  $$self{line}   = '';
  $$self{nchars} = 0;

  return 1; }

# opens a raw string
sub openString {
  my ($self, $string) = @_;
  # reset the state
  $$self{lineno} = 0;
  $$self{colno}  = 0;
  $$self{line}   = '';
  $$self{nchars} = 0;

  $$self{string} = $string;
  $$self{buffer} = [(defined $string ? splitLines($string) : ())];
  $$self{IN}     = undef;
  return; }

# close whatever was open
sub finalize {
  my ($self) = @_;

  # close the input if it exists
  if (defined($$self{IN})) {
    my $fh = \*{ $$self{IN} };
    close($fh);
  }
  $$self{IN} = undef;

  $$self{buffer} = [];
  $$self{lineno} = 0;
  $$self{colno}  = 0;
  $$self{line}   = '';
  $$self{nchars} = 0;
  return; }

# ===================================================================== #
# Reading Primitives
# ===================================================================== #

# read the next character from the input
# and return it (or undef if we ran out)
sub readChar {
  my ($self) = @_;

  # read our current state
  my $lineNo = $$self{lineno};
  my $colNo  = $$self{colno};
  my $eof    = $$self{at_eof};

  # if we have some pushback, restore the state of it and return
  my $pushback = $$self{pushback};
  if (defined($pushback)) {
    my ($char, $lineno, $colno, $at_eof) = @$pushback;
    $$self{pushback} = undef;

    $$self{lineno} = $lineno;
    $$self{colno}  = $colno;
    $$self{at_eof} = $at_eof;
    return $char, $lineNo, $colNo, $eof;
  }

  # if we reached the end of the file in a previous run
  # don't bother trying
  return undef, $lineNo, $colNo, $eof if $$self{at_eof};

  # if we still have characters left in the line, return those.
  if ($colNo < $$self{nchars}) {
    return substr($$self{line}, $$self{colno}++, 1), $lineNo, $colNo, $eof;

    # else read the next line
  } else {
    my $line = $self->readNextLine;

    # no more lines ...
    if (!defined($line)) {
      $$self{at_eof} = 1;
      $$self{colno}  = 0;
      $$self{lineno}++;
      return undef, $lineNo, $colNo, $eof;
    }

    $$self{line}   = $line;
    $$self{nchars} = length $line;

    $$self{lineno}++;
    $$self{colno} = 1;

    # TODO: this substr does not deal with unicode well
    # but we can expect those charact er
    return substr($line, 0, 1), $lineNo, $colNo, $eof;
  }
}

# like readChar, but doesn't return anything
sub eatChar {
  my ($self) = @_;

  # if we had some pushback
  # we just need to clear it.
  if (defined($$self{pushback})) {
    $$self{pushback} = undef;
    return;
  }

  # if we are at the end of the file, return
  return if $$self{at_eof};

  # if we have characters, increase and return.
  if ($$self{colno} < $$self{nchars}) {
    $$self{colno}++;
    return;
  } else {
    my $line = $self->readNextLine;

    # no more lines ...
    if (!defined($line)) {
      $$self{at_eof} = 1;
      $$self{colno}  = 0;
      $$self{lineno}++;
      return;
    }

    $$self{line}   = $line;
    $$self{nchars} = length $line;

    $$self{lineno}++;
    $$self{colno} = 1;
  }
}

# Unreads a char, i.e. puts a read char (along with appropriate state)
# bsack onto the pushback
sub unreadChar {
  my ($self, $char, $lineNo, $colNo, $eof) = @_;

  # if we did not change any lines
  # it is sufficient to revert the counter
  # and we do not need to use (potentially expensive) pushback
  my $nextLineNo = $$self{lineno};
  if ($nextLineNo eq $lineNo) {
    $$self{colno} = $colNo;

    # else we need to revert the current state onto pushback
    # because we can not undo the ->readLine
  } else {
    $$self{pushback} = [($char, $nextLineNo, $$self{colno}, $$self{at_eof})];
    $$self{lineno}   = $lineNo;
    $$self{colno}    = $colNo;
    $$self{at_eof}   = $eof;
  }
}

# looks at the next character that would be read with ->readChar
# and returns it without actually reading it
sub peekChar {
  my ($self) = @_;

  # if we have some pushback, return that immediatly
  # and do not call anything else
  return @{ $$self{pushback} } if defined($$self{pushback});

  # read our current state
  my $lineNo = $$self{lineno};
  my $colNo  = $$self{colno};
  my $eof    = $$self{at_eof};

  # if we have reached the end of the line, we can return now
  # and don't even bother trying anything else
  return undef, $lineNo, $colNo, 1 if $eof;

  # if we still have enough characters on the current line
  # then we can just return the current character
  return substr($$self{line}, $colNo, 1), $lineNo, $colNo, $eof if $colNo < $$self{nchars};

  # in all the other cases, we need to do a real readChar, unreadChar
  my @read = $self->readChar;
  $self->unreadChar(@read);

  return @read;
}

# read characters from the input as long as they match the callback 'pred'
# and return the chars that were read
sub readCharWhile {
  my ($self, $pred) = @_;

  my ($char, $colno, $lineno, $eof) = $self->readChar;
  my $chars = '';

  if (defined($char)) {
    # read while we are not at the end of the input
    # and are stil ok w.r.t the filter
    while (&{$pred}($char)) {
      $chars .= $char if defined($char);
      ($char, $colno, $lineno, $eof) = $self->readChar;
      last if $eof;
    }
  }

  # unread whatever is next and put it back on the stack
  $self->unreadChar($char, $colno, $lineno, $eof);

  # and return how many characters we skipped.
  return $chars;
}

# like readCharWhile, but doesn't return anything
sub eatCharWhile {
  my ($self, $pred) = @_;

  my ($char, $colno, $lineno, $eof) = $self->readChar;
  return unless defined($char);

  # read while we are not at the end of the input
  # and are stil ok w.r.t the filter
  while (&{$pred}($char)) {
    ($char, $colno, $lineno, $eof) = $self->readChar;
    last if $eof;
  }

  # unread whatever is next and put it back on the stack
  $self->unreadChar($char, $colno, $lineno, $eof);

  return;
}

# read all spaces from the input
sub readSpaces {
  my ($self) = @_;
  return $self->readCharWhile(sub { $_[0] =~ /\s/; });
}

# discard all spaces from the input
sub eatSpaces {
  my ($self) = @_;
  return $self->eatCharWhile(sub { $_[0] =~ /\s/; });
}

# ===================================================================== #
# Reading state
# ===================================================================== #

# returns a triple (line, column, at_eof)
sub getPosition {
  my ($self) = @_;
  return ($$self{lineno}, $$self{colno}, $$self{at_eof});
}

# ===================================================================== #
# Reading lines
# ===================================================================== #

# read the next line from the input

sub readNextLine {
  my ($self) = @_;

  unless (@{ $$self{buffer} }) {
    return unless $$self{IN};    # if we did not have an open file, return undef
    my $fh   = \*{ $$self{IN} };
    my $line = <$fh>;
    if (!defined $line) {
      close($fh); $$self{IN} = undef;
      return; }
    else {
      $$self{buffer} = [splitLines($$self{encoding}->decode($line))]; } }

  return (shift(@{ $$self{buffer} }) || '') . "\n"; }

# This is (hopefully) a platform independent way of splitting a string
# into "lines" ending with CRLF, CR or LF (DOS, Mac or Unix).
sub splitLines {
  my ($string) = @_;
  $string =~ s/(?:\015\012|\015|\012)/\n/sg;
  return split("\n", $string); }

1;
