# /=====================================================================\ #
# | MakeFile Maker for BibTeXML                                         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
use ExtUtils::MakeMaker;
use strict;
use warnings;
use FindBin;

WriteMakefile(NAME => 'Bi',
  AUTHOR             => 'Tom Wiesing <tom.wiesing@gmail.com>',
  ABSTRACT           => "a parser and interpreter for .bib and .bst files",
  VERSION            =>  '0.0.0',
  MIN_PERL_VERSION   => 5.010001,
  # A very restricted set of licenses are allowed here. No Creative Commons, eg.!
  # The tag open_source should be an Open Source Initiative approved license;
  # public domain is sorta included. See http://opensource.org/faq#public-domain
  LICENSE            => 'open_source',
  PREREQ_PM => {
    'Test::More'     => 0,
  },
  EXE_FILES => ['bin/bibtexmlc'],
  # link to  github location to newer MakeMaker
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
   'meta-spec' => { version => 2 },
   resources => {
     repository => {
       type => 'git',
       url => 'https://github.com/tkw1536/BibTeXML.git',
       web => 'https://github.com/tkw1536/BibTeXML'}}})
    : () ),
);

#======================================================================