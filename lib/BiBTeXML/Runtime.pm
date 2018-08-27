# /=====================================================================\ #
# |  BiBTeXML::Runtime                                                  | #
# | Runtime for BiBTeXML-generated perl code                            | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Runtime;
use strict;
use warnings;

use BiBTeXML::Runtime::Functions;
use BiBTeXML::Runtime::Builtins;

use base qw(Exporter);
our @EXPORT = qw(
  &defineEntryField &defineEntryInteger &defineEntryString &defineGlobalString &defineGlobalInteger &defineGlobalInteger &registerFunctionDefinition &defineMacro
  &readEntries &sortEntries &iterateFunction &reverseFunction
  &pushString &pushInteger &pushFunction
  &pushFunction &pushGlobalString &pushGlobalInteger &pushEntryField &pushEntryString &pushEntryInteger
  &lookupGlobalString &lookupGlobalInteger &lookupEntryString &lookupEntryInteger &lookupFunction

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

1;
