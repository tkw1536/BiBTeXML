use Test::More tests => 4;

use File::Basename;
use File::Spec;

# require
require_ok("BibTeXML::Common::StreamReader");
require_ok("BibTeXML::Bibliography::BibParser");


# create an input file
my $reader = BibTeXML::Common::StreamReader->new();
my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'kwarcbib', 'kwarc.bib');
$reader->openFile($path, "utf-8");

# parse kwarc.bib and measure the time it takes
my $start = time;
my ($results, $errors) = BibTeXML::Bibliography::BibParser::readFile($reader);
my $duration = time - $start;
diag("parsed kwarc.bib in $duration seconds");

# check that we did not make any errors
is(scalar(@$results), 6994, 'parses correct number of entries from kwarc.bib');
is(scalar(@$errors), 0, 'does not produce any errors parsing kwarc.bib');

1;