use BiBTeXML::Common::Test;
use Test::More tests => 2;

integrationTest( "cite everything", "01_complicated", );

integrationTest( "format.name\$ tests", "02_formatName", );
