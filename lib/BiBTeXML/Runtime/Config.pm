# /=====================================================================\ #
# |  BiBTeXML::Runtime::Config                                          | #
# | Configuration for a single run of a compiled .bst file              | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Config;
use strict;
use warnings;

use BiBTeXML::Runtime::Context;
use BiBTeXML::Runtime::Builtins;

sub new {
  my ($class, $name, $resultHandle, $outputHandle, $readers) = @_;

  # a new configuration for us to use
  my $context = BiBTeXML::Runtime::Context->new();

  return bless {
    name         => $name,           # the .bst (compiled) file name
    context      => $context,
    resultHandle => $resultHandle,
    outputHandle => $outputHandle,
    readers      => [@{$readers}]
  }, $class;
}

# writes a message of a given level to the output.
# supported levels are 'INFO', 'WARNING', 'ERROR'.
# location is going to be one of:

# - undef (no location information available)
# - 5-tuple (filename, sr, sc, er, ec) indicating a location within a file name
# - 3-tuple (filename, key, value) inidicating the location within a bib file
sub log {
  my ($self, $level, $message, $filename, $location) = @_;

  # call the handle we passed during construction
  &{ $$self{outputHandle} }($level, $message, $location);
}

# writes a message to the output
# gets passed a source which is either undef or a tuple ($filename, $key, $name) if it is known where this value comes from.
# this will get called frequently, so should be fast
sub write {
  my ($self, $string, $source) = @_;

  # call the handle we passed during construction
  &{ $$self{resultHandle} }($string, $source);
}

# returns the location of a given StyString within this file
sub location {
  my ($self, $styString) = @_;
  return [$$self{name}, @{ $styString->getSource }];
}

# gets the readers associated with this configuration
sub getReaders {
  my ($self) = @_;
  return @{ $$self{readers} };
}

# gets the context associated with this Configuration
sub getContext {
  my ($self) = @_;
  return $$self{context};
}

# initialises this context and registers all built-in functions
sub initContext {
  my ($self) = @_;

  # take the context
  my $context = $$self{context};

  # define the crossref field and sort.key$
  $context->defineVariable('crossref',  'ENTRY_FIELD');
  $context->defineVariable('sort.key$', 'ENTRY_STRING');

  # TODO: These will be ignored at runtime
  $context->assignVariable('global.max$', 'GLOBAL_INTEGER', ['INTEGER', 1000, undef]);
  $context->assignVariable('entry.max$',  'GLOBAL_INTEGER', ['INTEGER', 1000, undef]);

  # define all the built-in functions
  $context->assignVariable('>',  'FUNCTION', ['FUNCTION', \&builtinZg,   undef]);
  $context->assignVariable('<',  'FUNCTION', ['FUNCTION', \&builtinZl,   undef]);
  $context->assignVariable('=',  'FUNCTION', ['FUNCTION', \&builtinZe,   undef]);
  $context->assignVariable('+',  'FUNCTION', ['FUNCTION', \&builtinZp,   undef]);
  $context->assignVariable('-',  'FUNCTION', ['FUNCTION', \&builtinZm,   undef]);
  $context->assignVariable('*',  'FUNCTION', ['FUNCTION', \&builtinZa,   undef]);
  $context->assignVariable(':=', 'FUNCTION', ['FUNCTION', \&builtinZcZe, undef]);

  $context->assignVariable('add.period$',  'FUNCTION', ['FUNCTION', \&builtinAddPeriod,  undef]);
  $context->assignVariable('call.type$',   'FUNCTION', ['FUNCTION', \&builtinCallType,   undef]);
  $context->assignVariable('change.case$', 'FUNCTION', ['FUNCTION', \&builtinChangeCase, undef]);
  $context->assignVariable('chr.to.int$',  'FUNCTION', ['FUNCTION', \&builtinChrToInt,   undef]);
  $context->assignVariable('cite$',        'FUNCTION', ['FUNCTION', \&builtinCite,       undef]);
  $context->assignVariable('duplicate$',   'FUNCTION', ['FUNCTION', \&builtinDuplicate,  undef]);
  $context->assignVariable('empty$',       'FUNCTION', ['FUNCTION', \&builtinEmpty,      undef]);
  $context->assignVariable('format.name$', 'FUNCTION', ['FUNCTION', \&builtinFormatName, undef]);
  $context->assignVariable('if$',          'FUNCTION', ['FUNCTION', \&builtinIf,         undef]);
  $context->assignVariable('int.to.chr$',  'FUNCTION', ['FUNCTION', \&builtinIntToChr,   undef]);
  $context->assignVariable('int.to.str$',  'FUNCTION', ['FUNCTION', \&builtinIntToStr,   undef]);
  $context->assignVariable('missing$',     'FUNCTION', ['FUNCTION', \&builtinMissing,    undef]);
  $context->assignVariable('newline$',     'FUNCTION', ['FUNCTION', \&builtinNewline,    undef]);
  $context->assignVariable('num.names$',   'FUNCTION', ['FUNCTION', \&builtinNumNames,   undef]);
  $context->assignVariable('pop$',         'FUNCTION', ['FUNCTION', \&builtinPop,        undef]);
  $context->assignVariable('preamble$',    'FUNCTION', ['FUNCTION', \&builtinPreamble,   undef]);
  $context->assignVariable('purify$',      'FUNCTION', ['FUNCTION', \&builtinPurify,     undef]);
  $context->assignVariable('quote$',       'FUNCTION', ['FUNCTION', \&builtinQuote,      undef]);
  $context->assignVariable('skip$',        'FUNCTION', ['FUNCTION', \&builtinSkip,       undef]);
  $context->assignVariable('stack$',       'FUNCTION', ['FUNCTION', \&builtinStack,      undef]);
  $context->assignVariable('substring$',   'FUNCTION', ['FUNCTION', \&builtinSubstring,  undef]);
  $context->assignVariable('swap$',        'FUNCTION', ['FUNCTION', \&builtinSwap,       undef]);
  $context->assignVariable('text.length$', 'FUNCTION', ['FUNCTION', \&builtinTextLength, undef]);
  $context->assignVariable('text.prefix$', 'FUNCTION', ['FUNCTION', \&builtinTextPrefix, undef]);
  $context->assignVariable('top$',         'FUNCTION', ['FUNCTION', \&builtinTop,        undef]);
  $context->assignVariable('type$',        'FUNCTION', ['FUNCTION', \&builtinType,       undef]);
  $context->assignVariable('warning$',     'FUNCTION', ['FUNCTION', \&builtinWarning,    undef]);
  $context->assignVariable('while$',       'FUNCTION', ['FUNCTION', \&builtinWhile,      undef]);
  $context->assignVariable('width$',       'FUNCTION', ['FUNCTION', \&builtinWidth,      undef]);
  $context->assignVariable('write$',       'FUNCTION', ['FUNCTION', \&builtinWrite,      undef]);
}

1;
