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
    chars => [], nchars => 0, colno => 0,
    lineno => 0, at_eof => 0,

    # pushback, contains ($char, $line, $col, $at_eof)
    pushback => [],

    # entries in this bibfile
    entries => [()],
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
  $$self{IN}     = $IN;
  $$self{buffer} = [];
  $$self{encoding} = $encoding || 'utf-8';
    # reset the state
  $$self{lineno} = 0;
  $$self{colno}  = 0;
  $$self{chars}  = [];
  $$self{nchars} = 0;

  return 1; }

# opens a raw string
sub openString {
  my ($self, $string) = @_;
  # reset the state
  $$self{lineno} = 0;
  $$self{colno}  = 0;
  $$self{chars}  = [];
  $$self{nchars} = 0;

  $$self{string} = $string;
  $$self{buffer} = [(defined $string ? splitLines($string) : ())];
  $$self{IN} = undef;
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
  $$self{chars}  = [];
  $$self{nchars} = 0;
  return; }

# ===================================================================== #
# Reading Primitives
# ===================================================================== #

# read the next character from the input
# and return it (or undef if we ran out)
sub readChar {
  my ($self) = @_;

  # if we have some pushback, restore the state of it and return
  if (scalar(@{ $$self{pushback} })) {
    my ($char, $lineno, $colno, $at_eof) = @{pop(@{ $$self{pushback} })};

    $$self{lineno} = $lineno;
    $$self{colno}  = $colno;
    $$self{at_eof} = $at_eof;
    return $char;
  }

  # if we reached the end of the file in a previous run
  # don't bother trying
  return undef if $$self{at_eof};

  # iterate until we find a character or run out
  while (1) {
    if ($$self{colno} >= $$self{nchars}) {
      $$self{lineno}++;
      $$self{colno} = 0;
      my $line = $self->readNextLine;

      # no more lines ...
      if (!defined($line)) {
        $$self{at_eof} = 1;
        $$self{chars}  = [];
        $$self{nchars} = 0;
        return;
      }

      $$self{chars}  = splitChars($line);
      $$self{nchars} = scalar(@{ $$self{chars} });
    }

    # if the line is non-empty, return the first character
    if ($$self{colno} < $$self{nchars}) {
      return $$self{chars}[$$self{colno}++];
    }
  }
}

sub peekChar {
  my ($self) = @_;
  # store state before reading
  my $lineNo = $$self{lineno};
  my $colNo  = $$self{colno};
  my $eof    = $$self{at_eof};

  # read a character and put it on the pushback
  my $char       = $self->readChar;
  my $nextLineNo = $$self{lineno};
  my $nextColNo  = $$self{colno};
  my $nextEoF    = $$self{at_eof};
  push(@{ $$self{pushback} }, [($char, $nextLineNo, $nextColNo, $nextEoF)]);

  # restore the state
  $$self{lineno} = $lineNo;
  $$self{colno}  = $colNo;
  $$self{at_eof} = $eof;

  # and return the character we read
  return $char;
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

  if (defined($$self{IN})) {
    return $self->readNextLineFromFile();
  } else {
    return $self->readNextLineFromString();
} }

sub readNextLineFromString {
  my ($self) = @_;
  return unless scalar(@{ $$self{buffer} });
  my $line = shift(@{ $$self{buffer} });
  return $line . "\r";    # we always have a carriage return
}

sub readNextLineFromFile {
  my ($self) = @_;
  if (!scalar(@{ $$self{buffer} })) {
    return unless $$self{IN};
    my $fh   = \*{ $$self{IN} };
    my $line = <$fh>;
    if (!defined $line) {
      close($fh); $$self{IN} = undef;
      return; }
    else {
      push(@{ $$self{buffer} }, splitLines($line)); } }

  my $line = shift(@{ $$self{buffer} });
  if (defined $line) {
      $line = decode($$self{encoding}, $line, Encode::FB_DEFAULT); } # todo: proper encoding
  else {
    $line = ''; }
  $line .= "\r";                        # put line ending back!
  return $line; }

# This is (hopefully) a platform independent way of splitting a string
# into "lines" ending with CRLF, CR or LF (DOS, Mac or Unix).
# Note that TeX considers newlines to be \r, ie CR, ie ^^M
sub splitLines {
  my ($string) = @_;
  $string =~ s/(?:\015\012|\015|\012)/\r/sg;    #  Normalize remaining
  return split("\r", $string); }                # And split.

# This is (hopefully) a correct way to split a line into "chars",
# or what is probably more desired is "Grapheme clusters" (even "extended")
# These are unicode characters that include any following combining chars, accents & such.
# I am thinking that when we deal with unicode this may be the most correct way?
# If it's not the way XeTeX does it, perhaps, it must be that ALL combining chars
# have to be converted to the proper accent control sequences!
sub splitChars {
  my ($line) = @_;
  return [$line =~ m/\X/g]; }

1;
