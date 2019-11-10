use BiBTeXML::Common::Test;
use Test::More tests => 1;

integrationTest(
    "cite everything",
    "t/fixtures/bstfiles/plain.bst",
    [ ( "t/fixtures/bibfiles/complicated.bib", ) ],
    "*",
    undef,
    "t/fixtures/integration/01_everything.tex"
);
