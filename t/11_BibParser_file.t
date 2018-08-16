use Test::More tests => 3;

use File::Basename;
use File::Spec;

use Time::HiRes qw(time);


subtest "requirements" => sub {
    require_ok("BiBTeXML::Common::StreamReader");
    require_ok("BiBTeXML::Bibliography::BibParser");
};

doesParseFile("complicated.bib", 6);
doesParseFile("kwarc.bib", 6994);

sub doesParseFile {
    my ($name, $expectEntries) = @_;

    subtest $name => sub {
        # create an input file
        my $reader = BiBTeXML::Common::StreamReader->new();
        my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'bibfiles', $name);
        $reader->openFile($path, "utf-8");

        # parse kwarc.bib and measure the time it takes
        my $start = time;
        my ($results, $errors) = BiBTeXML::Bibliography::BibParser::readFile($reader);
        my $duration = time - $start;

        # check that we did not make any errors
        is(scalar(@$results), $expectEntries, 'parses correct number of entries from ' . $name);
        is(scalar(@$errors),  0,              'does not produce any errors parsing ' . $name);

        diag("parsed $name in $duration seconds");
    };
}


1;
