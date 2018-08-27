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
our @EXPORT = (
  qw( &defineEntryField &defineEntryInteger &defineEntryString &defineGlobalString &defineGlobalInteger &defineGlobalInteger &registerFunctionDefinition &defineMacro ),
  qw( &readEntries &sortEntries &iterateFunction &reverseFunction ),
  qw( &pushString &pushInteger &pushFunction ),
  qw( &pushFunction &pushGlobalString &pushGlobalInteger &pushEntryField &pushEntryString &pushEntryInteger ),
  qw( &lookupGlobalString &lookupGlobalInteger &lookupEntryString &lookupEntryInteger &lookupFunction ),
  qw(
    &builtinZg &builtinZl &builtinZe &builtinZp &builtinZm &builtinZa
    &builtinZcZe &builtinAddPeriod &builtinCallType &builtinChangeCase
    &builtinChrToInt &builtinCite &builtinDuplicate &builtinEmpty
    &builtinFormatName &builtinIf &builtinIntToChr &builtinIntToStr
    &builtinMissing &builtinNewline &builtinNumNames &builtinPop
    &builtinPreamble &builtinPurify &builtinQuote &builtinSkip
    &builtinStack &builtinSubstring &builtinSwap &builtinTextLength
    &builtinTextPrefix &builtinTop &builtinType &builtinWarning
    &builtinWhile &builtinWidth &builtinWrite
    )
);

1;
