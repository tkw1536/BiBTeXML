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
use BiBTeXML::Runtime::Functions;

sub new {
  my ($class, $resultHandle, $outputHandle, $readers) = @_;

  # a new configuration for us to use
  my $context = BiBTeXML::Runtime::Context->new();

  return bless {
    context      => $context,
    resultHandle => $resultHandle,
    outputHandle => $outputHandle,
    readers      => [@{$readers}]
  }, $class;
}

# writes a message of a given level to the output.
# supported levels are 'INFO', 'WARNING', 'ERROR'.
sub log {
  my ($self, $level, $message, $location) = @_;

  # call the handle we passed during construction
  &{ $$self{outputHandle} }($level, $message, $location);
}

# writes a message to the output
# gets passed a source which is either undef or a tuple ($key, $name) where this value comes from.
# this will get called frequently, so should be fast
sub write {
  my ($self, $string, $source) = @_;

  # call the handle we passed during construction
  &{ $$self{resultHandle} }($string, $source);
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
  # TODO: We want to actually make references to all of them.
  $context->assignVariable('>',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('>',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('<',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('=',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('+',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('-',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('*',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable(':=', 'FUNCTION', ['FUNCTION', undef, undef]);

  $context->assignVariable('add.period$',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('call.type$',   'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('change.case$', 'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('chr.to.int$',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('cite$',        'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('duplicate$',   'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('empty$',       'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('format.name$', 'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('if$',          'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('int.to.chr$',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('int.to.str$',  'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('missing$',     'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('newline$',     'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('num.names$',   'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('pop$',         'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('preamble$',    'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('purify$',      'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('quote$',       'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('skip$',        'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('stack$',       'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('substring$',   'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('swap$',        'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('text.length$', 'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('text.prefix$', 'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('top$',         'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('type$',        'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('warning$',     'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('while$',       'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('width$',       'FUNCTION', ['FUNCTION', undef, undef]);
  $context->assignVariable('write$',       'FUNCTION', ['FUNCTION', undef, undef]);
}
