use BiBTeXML::Common::Test;
use Test::More tests => 3;

integrationTest( "cite everything", "01_complicated", );

integrationTest( "format.name\$ tests", "02_formatName", );

integrationTest( "change.case\$ tests", "03_changeCase", );