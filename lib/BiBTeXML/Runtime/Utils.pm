# /=====================================================================\ #
# |  BiBTeXML::Runtime::Utils                                           | #
# | Various runtime utility functions                                   | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Utils;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = (
  qw( &concatString &simplifyString &applyPatch ),
);

# given two runtime strings, join them and their sources together
# and return a new runtime string
sub concatString {
  my ($stringA, $sourceA, $stringB, $sourceB) = @_;

  # join the strings and sources
  my @strings = (@$stringA, @$stringB);
  my @sources = (@$sourceA, @$sourceB);

  my @theString  = ();
  my @theSources = ();

  my ($hasElement, $string, $source, $prevSource) = (0);
  while (defined($string = shift(@strings))) {
    $source = shift(@sources);

    # if we have a non-empty string
    unless ($string eq '') {
      # if the previous source is also undef, then we can join them directly
      if ($hasElement && !defined($prevSource) && !defined($source)) {
        $theString[-1] .= $string;
      } else {
        push(@theString,  $string);
        push(@theSources, $source);
      }

      $prevSource = $source;
      $hasElement = 1;
    }
  }

  # and return the strings and sources
  return [@theString], [@theSources];
}

# given a runtime string turn it into a single string and useful source
sub simplifyString {
  my ($string, $sources) = @_;

  # return the first 'defined' source
  # i.e. one that comes from a source file.
  my ($source, $asource);
  foreach $asource (@$sources) {
    $source = $asource;
    last if defined($source);
  }

  return join('', @$string), $source;
}

# given an runtime old string with source references
# and apply a plain-text patch function $patch to it.
sub applyPatch {
  my ($oldString, $oldSource, $patch) = @_;

  # TODO: For the moment this function is pretty stupid
  # and only knows about unchanged and changed strings

  # simplify the old string
  my ($theOldString, $theOldSource) = simplifyString($oldString, $oldSource);

  # apply the patch
  my $theNewString = &{$patch}($theOldString);

  # if nothing changed, return as is
  if ($theOldString eq $theNewString) {
    return $oldString, $oldSource;

    # else return the simplified source
  } else {
    return [$theNewString], [$theOldSource];
  }
}
1;
