use BiBTeXML::Common::Test;
use Test::More tests => 3;

subtest "requirements" => sub {
  plan tests => 2;

  use_ok("BiBTeXML::Common::StreamReader");
  use_ok("BiBTeXML::Runtime::Context");
};

my $context = BiBTeXML::Runtime::Context->new();
my ($reader, $path) = makeFixtureReader(__FILE__, 'bibfiles', 'complicated.bib');

subtest "reading entries" => sub {
  plan tests => 2;

  # read them for the first time
  my ($result, $error) = $context->readEntries([$reader], ["*"]);
  is_deeply([$result, $error], [0, []], 'reading entries');

  # read them again
  ($result, $error) = $context->readEntries([$reader], ["*"]);
  is_deeply([$result, $error], [1, undef], 'reading entries again');
};

subtest "getting defined values" => sub {
  plan tests => 8;

  # define field variables
  $context->defineVariable('author',     'ENTRY_FIELD');
  $context->defineVariable('conference', 'ENTRY_FIELD');
  $context->defineVariable('acount',     'ENTRY_INTEGER');

  # enter the first entry
  $context->setEntry($context->getEntries->[0]);

  # try and get a couple of things of it
  is_deeply([$context->getVariable('author')], ['STRING', ['Bart KiersMr. X'], [[$path, 'MRx05', 'author']]], 'Getting a defined field');
  is_deeply([$context->getVariable('conference')], ['MISSING', undef, [$path, 'MRx05', 'conference']], 'Getting a missing field');
  is_deeply([$context->getVariable('acount')], ['UNSET', undef, undef], 'Getting an unset variable ');

  # define and get again
  is_deeply($context->setVariable('acount', ['INTEGER', 0, undef]), 0, 'Setting an unset variable ');
  is_deeply($context->setVariable('conference', ['INTEGER', 0, undef]), 3, 'Setting a field');
  is_deeply([$context->getVariable('acount')], ['INTEGER', 0, undef], 'Getting a set variable ');

  # switch to another entry, and we should get different values
  $context->setEntry($context->getEntries->[1]);
  is_deeply([$context->getVariable('acount')], ['UNSET', undef, undef], 'Getting an unset variable ');
  is_deeply([$context->getVariable('author')], ['STRING', ['Oren Patashnik'], [[$path, 'patashnik-bibtexing', 'author']]], 'Getting a defined field');

};
