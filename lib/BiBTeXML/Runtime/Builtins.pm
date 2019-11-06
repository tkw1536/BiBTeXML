# /=====================================================================\ #
# |  BiBTeXML::Runtime::Builtin                                         | #
# | BibTeX builtin functions                                            | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Builtins;
use strict;
use warnings;

use BiBTeXML::Runtime::Utils;
use BiBTeXML::Runtime::Strings;
use BiBTeXML::Runtime::Names;

use base qw(Exporter);
our @EXPORT = qw(
  &builtinZg &builtinZl &builtinZe &builtinZp &builtinZm &builtinZa
  &builtinZcZe &builtinAddPeriod &builtinCallType &builtinChangeCase
  &builtinChrToInt &builtinCite &builtinDuplicate &builtinEmpty
  &builtinFormatName &builtinIf &builtinIntToChr &builtinIntToStr
  &builtinMissing &builtinNewline &builtinNumNames &builtinPop
  &builtinPreamble &builtinPurify &builtinQuote &builtinSkip
  &builtinStack &builtinSubstring &builtinSwap &builtinTextLength
  &builtinTextPrefix &builtinTop &builtinType &builtinWarning
  &builtinWhile &builtinWidth &builtinWrite
);

# builtin function >
sub builtinZg {
  my ($context, $config, $source) = @_;
  my ($i1tp, $i1) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i1tp);
  my ($i2tp, $i2) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i2tp);

  $context->pushInteger($i2 > $i1 ? 1 : 0);
}

# builtin function <
sub builtinZl {
  my ($context, $config, $source) = @_;
  my ($i1tp, $i1) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i1tp);
  my ($i2tp, $i2) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i2tp);

  $context->pushInteger($i2 < $i1 ? 1 : 0);
}

# builtin function =
sub builtinZe {
  my ($context, $config, $source) = @_;
  my ($tp, $value) = $context->popStack;
  unless (defined($tp)) {
    $config->log('WARN', "Unable to pop empty stack", $config->location($source));
  }
  if ($tp eq 'INTEGER') {
    my $i1 = $value;
    my ($i2tp, $i2) = popType($context, $config, 'INTEGER', undef, $source);
    return unless defined($i2tp);
    $context->pushInteger($i1 eq $i2 ? 1 : 0);
  } elsif ($tp eq 'STRING') {
    my $s1 = join('', @$value);
    my ($s2tp, $s2) = popType($context, $config, 'STRING', undef, $source);
    return unless defined($s2tp);
    $s2 = join('', @$s2);
    $context->pushInteger($s1 eq $s2 ? 1 : 0);
  } else {
    $config->log('WARN', 'Expected to find a STRING or an INTEGER on the stack. ', $config->location($source));
  }
}

# builtin function +
sub builtinZp {
  my ($context, $config, $source) = @_;
  my ($i1tp, $i1) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i1tp);
  my ($i2tp, $i2) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i2tp);

  $context->pushInteger($i2 + $i1);
}

# builtin function -
sub builtinZm {
  my ($context, $config, $source) = @_;
  my ($i1tp, $i1) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i1tp);
  my ($i2tp, $i2) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i2tp);

  $context->pushInteger($i2 - $i1);
}

# builtin function *
sub builtinZa {
  my ($context, $config, $source) = @_;
  my ($s1tp, $s1, $ss1) = popType($context, $config, 'STRING', undef, $source);
  return unless defined($s1tp);
  my ($s2tp, $s2, $ss2) = popType($context, $config, 'STRING', undef, $source);
  return unless defined($s2tp);

  my ($ns, $nss) = concatString($s2, $ss2, $s1, $ss1);
  $context->pushStack('STRING', $ns, $nss);
}

# builtin function :=
# 0 if ok, 1 if it doesn't exist,  2 if an invalid context, 3 if read-only, 4 if unknown type
sub builtinZcZe {
  my ($context, $config, $source) = @_;

  # pop the variable type and name to be assigned
  my ($rtp, $rv) = popType($context, $config, 'REFERENCE', undef, $source);
  return unless defined($rtp);
  my ($rvt, $name) = @$rv;

  # pop the value to assign
  my ($t, $v, $s) = $context->popStack;
  return $config->log('WARN', 'Attempted to pop the empty stack', $config->location($source)) unless defined($t);

  # and do it!
  my $asr = $context->setVariable($name, [$t, $v, $s]);
  if ($asr eq 1) {
    $config->log('WARN', "Can not set $name: Does not exist. ", $config->location($source));
  } elsif ($asr eq 2) {
    $config->log('WARN', "Can not set $name: Not in an entry context. ", $config->location($source));
  } elsif ($asr eq 4) {
    $config->log('WARN', "Can not set $name: Read-only. ", $config->location($source));
  } elsif ($asr eq 4) {
    $config->log('WARN', "Can not set $name: Unknown type. ", $config->location($source));
  }
}

# builtin function add.period$
sub builtinAddPeriod {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($newStrings, $newSources) = applyPatch($strings, $sources, \&addPeriod, 'inplace');
    $context->pushStack('STRING', $newStrings, $newSources);
  }
}

# builtin function call.type$
sub builtinCallType {
  my ($context, $config, $source) = @_;
  my $entry = $context->getEntry;
  if ($entry) {
    my $tp = $entry->getType;
    my ($ftype, $value) = $context->getVariable($tp);
    unless (defined($ftype) && $ftype eq 'FUNCTION') {
      ($ftype, $value) = $context->getVariable("default.type");
      unless (defined($ftype) && $ftype eq 'FUNCTION') {
        $config->log('WARN', 'Can not call.type$: Unknown entrytype type ' . $tp . ' and no default handler has been defined. ', $config->location($source));
        return;
      }
    }
    # call the type function
    &{$value}($context, $config);
  } else {
    $config->log('WARN', 'Can not call.type$: No active entry. ', $config->location($source));
  }
}

# builtin function change.case$
sub builtinChangeCase {
  my ($context, $config, $source) = @_;

  # get the case string
  my ($ctp, $cstrings) = popType($context, $config, 'STRING', undef, $source);
  return unless $ctp;
  $cstrings = join('', $cstrings);

  # pop the final string
  my ($stype, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);
  return unless defined($stype);

  # add the text prefix and push it to the stack
  my ($newStrings, $newSources) = applyPatch($strings, $sources, sub {
      return changeCase('' . $_[0], $cstrings);
  }, 'inplace');
  $context->pushStack('STRING', $newStrings, $newSources);
}

# builtin function chr.to.int$
sub builtinChrToInt {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($str, $src) = simplifyString($strings, $sources);
    if (length($str) ne 1) {
      $context->pushStack('INTEGER', ord($str), $src);
    } else {
      $config->log('WARN', 'Expected a single character string on the stack, but got ' . length($str) . ' characters. ', $config->location($source));
    }
  }
}

# builtin function cite$
sub builtinCite {
  my ($context, $config, $source) = @_;
  my $entry = $context->getEntry;
  if ($entry) {
    $context->pushStack('STRING', [$entry->getKey], [[$entry->getName, $entry->getKey, '']]);
  } else {
    $config->log('WARN', 'Can not push the entry key: No active entry. ', $config->location($source));
  }
}

# builtin function duplicate$
sub builtinDuplicate {
  my ($context, $config, $source) = @_;
  $config->log('WARN', 'Attempted to duplicate the empty stack', $config->location($source))
    unless $context->duplicateStack;
}

# builtin function empty$
sub builtinEmpty {
  my ($context, $config, $source) = @_;
  my ($tp, $value) = $context->popStack;
  return $config->log('WARN', 'Attempted to pop the empty stack', $config->location($source)) unless defined($tp);
  if ($tp eq 'MISSING') {
    $context->pushInteger(1);
  } elsif ($tp eq 'STRING') {
    $value = join('', @$value);
    $context->pushInteger(($value =~ /^\s*$/) ? 1 : 0);
  } else {
    $context->pushInteger(0);
  }
}

# builtin function format.name$
sub builtinFormatName {
  my ($context, $config, $source) = @_;

  # get the format string
  my ($ftp, $fstrings) = popType($context, $config, 'STRING', undef, $source);
  return unless $ftp;
  $fstrings = join('', @$fstrings);

  # get the length
  my ($itp, $integer, $isource) = popType($context, $config, 'INTEGER', undef, $source);
  return unless $itp;

  # pop the final name string
  my ($stype, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);
  return unless defined($stype);

  # add the text prefix and push it to the stack
  my ($newStrings, $newSources) = applyPatch($strings, $sources, sub {
      my @names = splitNames($_[0] . '');
      my $name = $names[$integer - 1] || '';    # TODO: Warn if missing
      my ($fname, $error) = formatName("$name", $fstrings);
      $config->log('WARN', "Unable to format name: $error", $config->location($source)) if defined($error);
      return defined($fname) ? $fname : '';
  }, 0);
  $context->pushStack('STRING', $newStrings, $newSources);
}

# builtin function if$
sub builtinIf {
  my ($context, $config, $source) = @_;
  my ($f1type, $f1) = popFunction($context, $config, $source);
  return unless defined($f1type);
  my ($f2type, $f2) = popFunction($context, $config, $source);
  return unless defined($f2type);

  my ($itype, $integer) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($itype);

  if ($integer > 0) {
    &{$f2}($context, $config);
  } else {
    &{$f1}($context, $config);
  }
}

# builtin function int.to.chr$
sub builtinIntToChr {
  my ($context, $config, $source) = @_;
  my ($type, $integer, $isource) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($type);
  $context->pushStack('STRING', [chr($integer)], [$isource]);
}

# builtin function int.to.str$
sub builtinIntToStr {
  my ($context, $config, $source) = @_;
  my ($type, $integer, $isource) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($type);
  $context->pushStack('STRING', ["$integer"], [$isource]);
}

# builtin function missing$
sub builtinMissing {
  my ($context, $config, $source) = @_;
  my ($tp) = $context->popStack;
  unless (defined($tp)) {
    $config->log('WARN', "Unable to pop empty stack", $config->location($source));
  } else {
    $context->pushInteger(($tp eq 'MISSING') ? 1 : 0);
  }
}

# builtin function newline$
sub builtinNewline {
  my ($context, $config, $source) = @_;
  $config->write("\n");
}

# builtin function num.names$
sub builtinNumNames {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($str, $src) = simplifyString($strings, $sources);
    $context->pushStack('INTEGER', numNames($str), [$src]);
  }
}

# builtin function pop$
sub builtinPop {
  my ($context, $config, $source) = @_;
  my ($tp) = $context->popStack;
  unless (defined($tp)) {
    $config->log('WARN', "Unable to pop empty stack", $config->location($source));
  }
}

# builtin function preamble$
sub builtinPreamble {
  my ($context, $config, $source) = @_;
  my ($strings, $sources) = $context->getPreamble;

  $context->pushStack('STRING', $strings, $sources);
}

# builtin function purify$
sub builtinPurify {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($newStrings, $newSources) = applyPatch($strings, $sources, \&textPurify, 'inplace');
    $context->pushStack('STRING', $newStrings, $newSources);
  }
}

# builtin function quote$
sub builtinQuote {
  my ($context, $config, $source) = @_;
  $context->pushString("\"");
}

# builtin function skip$
sub builtinSkip {
  my ($context, $config, $source) = @_;
  # does nothing
}

# builtin function stack$
sub builtinStack {
  my ($context, $config, $source) = @_;
  my ($tp,      $value,  $src)    = $context->popStack;
  while (defined($tp)) {
    $config->log('DEBUG', fmtType($tp, $value, $src));
    ($tp, $value, $src) = $context->popStack;
  }
}

# builtin function substring$
sub builtinSubstring {
  my ($context, $config, $source) = @_;

  # pop the first integer
  my ($i1t, $i1, $i1source) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i1t);

  # pop the second integer
  my ($i2t, $i2, $i2source) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($i2t);

  # pop the string
  my ($stype, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);
  return unless defined($stype);

  # add the text prefix and push it to the stack
  my ($newStrings, $newSources) = applyPatch($strings, $sources, sub {
      return textSubstring($_[0] . '', $i2, $i1);
  }, 'inplace');
  $context->pushStack('STRING', $newStrings, $newSources);
}

# builtin function swap$
sub builtinSwap {
  my ($context, $config, $source) = @_;
  my ($at,      $as,     $ass)    = $context->popStack;
  my ($bt,      $bs,     $bss)    = $context->popStack;
  if (!defined($bt)) {
    $config->log('WARN', 'Need at least two elements on the stack to swap. ', $config->location($source));
    return;
  }
  $context->pushStack($at, $as, $ass);
  $context->pushStack($bt, $bs, $bss);
}

# builtin function text.length$
sub builtinTextLength {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($str, $src) = simplifyString($strings, $sources);
    $context->pushStack('INTEGER', length($str), $src);
  }
}

# builtin function text.prefix$
sub builtinTextPrefix {
  my ($context, $config, $source) = @_;

  # pop the integer
  my ($itype, $integer, $isource) = popType($context, $config, 'INTEGER', undef, $source);
  return unless defined($itype);

  # pop and simplify the string
  my ($stype, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);
  return unless defined($stype);

  # add the text prefix and push it to the stack
  my ($newStrings, $newSources) = applyPatch($strings, $sources, sub {
      return textPrefix($_ . '', $integer, 'inplace');
  });
  $context->pushStack('STRING', $newStrings, $newSources);

}

# builtin function top$
sub builtinTop {
  my ($context, $config, $source) = @_;
  my ($tp,      $value,  $src)    = $context->popStack;
  unless (defined($tp)) {
    $config->log('DEBUG', fmtType($tp, $value, $src));
  } else {
    $config->log('WARN', "Unable to pop empty stack", $config->location($source));
  }
}

# builtin function type$
sub builtinType {
  my ($context, $config, $source) = @_;
  my $entry = $context->getEntry;
  if ($entry) {
    my $tp = $entry->getType;
    $tp = '' unless $context->hasVariable($tp, 'FUNCTION');
    $context->pushStack('STRING', [$tp], [[$entry->getName, $entry->getKey]]);
  } else {
    $context->pushStack('STRING', [''], [undef]);
  }
}

# builtin function warning$
sub builtinWarning {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);
  if (defined($type)) {
    my ($str, $src) = simplifyString($strings, $sources);
    $config->log('WARN', $str, $src);
  }
}

# builtin function while$
sub builtinWhile {
  my ($context, $config, $source) = @_;
  my ($f1type, $f1) = popFunction($context, $config, $source);
  return unless defined($f1type);
  my ($f2type, $f2) = popFunction($context, $config, $source);
  return unless defined($f2type);

  while (1) {
    &{$f2}($context, $config, $source);

    my ($itype, $integer) = popType($context, $config, 'INTEGER', undef, $source);
    return unless defined($itype);

    if ($integer > 0) {
      &{$f1}($context, $config, $source);
    } else {
      last;
    }
  }

}

# builtin function width$
sub builtinWidth {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($str, $src) = simplifyString($strings, $sources);
    $context->pushStack('INTEGER', textWidth($str), $src);
  }
}

# builtin function write$
sub builtinWrite {
  my ($context, $config, $source) = @_;
  my ($type, $strings, $sources) = popType($context, $config, 'STRING', undef, $source);

  # if we have a string, that's ok.
  if (defined($type)) {
    my ($str, $src);
    foreach $str (@$strings) {
      $src = shift(@$sources);
      $config->write($str, $src);
    }
  }

}

1;
