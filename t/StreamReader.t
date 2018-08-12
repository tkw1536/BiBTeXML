use Test::More tests => 3;

use File::Basename;
use File::Spec;

# we should be able to read the module
require_ok("BibTeXML::Common::StreamReader");

subtest 'String Hello world' => sub {
    plan tests => 16;

    # creating a reader from a string should work
    my $reader = BibTeXML::Common::StreamReader->new();
    $reader->openString("hello\nworld");

    peeks($reader,  "1st character", "h",  0, 0, 0);
    reads($reader,  "1st character", "h",  1, 1, 0);

    peeks($reader,  "2nd character", "e",  1, 1, 0);
    reads($reader,  "2nd character", "e",  1, 2, 0);
    
    reads($reader,  "3rd character", "l",  1, 3, 0);
    reads($reader,  "4th character", "l",  1, 4, 0);
    reads($reader,  "5th character", "o",  1, 5, 0);
    reads($reader,  "6th character", "\r", 1, 6, 0);

    peeks($reader,  "7th character", "w",  1, 6, 0);
    reads($reader,  "7th character", "w",  2, 1, 0);
    
    reads($reader,  "8th character", "o",  2, 2, 0);
    reads($reader,  "9th character", "r",  2, 3, 0);
    reads($reader, "10th character", "l",  2, 4, 0);
    reads($reader, "11th character", "d",  2, 5, 0);
    reads($reader, "12th character", "\r", 2, 6, 0);
    reads($reader, "13th character", undef,  3, 0, 1);

    $reader->finalize;
};

subtest 'File Hello World' => sub {
    plan tests => 16;

    # creating a reader from a string should work
    my $reader = BibTeXML::Common::StreamReader->new();
    my $path = File::Spec->join(dirname(__FILE__), 'fixtures', 'helloworld.txt');
    $reader->openFile($path, "utf-8");

    peeks($reader,  "1st character", "h",  0, 0, 0);
    reads($reader,  "1st character", "h",  1, 1, 0);

    peeks($reader,  "2nd character", "e",  1, 1, 0);
    reads($reader,  "2nd character", "e",  1, 2, 0);
    
    reads($reader,  "3rd character", "l",  1, 3, 0);
    reads($reader,  "4th character", "l",  1, 4, 0);
    reads($reader,  "5th character", "o",  1, 5, 0);
    reads($reader,  "6th character", "\r", 1, 6, 0);

    peeks($reader,  "7th character", "w",  1, 6, 0);
    reads($reader,  "7th character", "w",  2, 1, 0);
    
    reads($reader,  "8th character", "o",  2, 2, 0);
    reads($reader,  "9th character", "r",  2, 3, 0);
    reads($reader, "10th character", "l",  2, 4, 0);
    reads($reader, "11th character", "d",  2, 5, 0);
    reads($reader, "12th character", "\r", 2, 6, 0);
    reads($reader, "13th character", undef,  3, 0, 1);

    $reader->finalize;
};


#####
# Test helper function
#####
sub reads {
    my ($reader, $name, $echar, $eline, $ecol, $eeof) = @_;
    subtest "read $name" => sub {
        plan tests => 4;
        
        my $gchar = $reader->readChar;
        my ($gline, $gcol, $geof) = $reader->getPosition;

        is($gchar, $echar, "getChar");
        is($gline, $eline, "lineNo");
        is($gcol, $ecol, "colNo");
        is($geof, $eeof, "eof");
    };
    
}

sub peeks {
    my ($reader, $name, $echar, $eline, $ecol, $eeof) = @_;
    subtest "peek $name" => sub {
        plan tests => 4;
        my $gchar = $reader->peekChar;
        my ($gline, $gcol, $geof) = $reader->getPosition;

        is($gchar, $echar, "getChar");
        is($gline, $eline, "lineNo");
        is($gcol, $ecol, "colNo");
        is($geof, $eeof, "eof");
    };
}