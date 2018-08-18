# BiBTeXML

[![Build Status](https://travis-ci.org/tkw1536/BibTeXML.svg?branch=master)](https://travis-ci.org/tkw1536/BibTeXML)

__Still a work in progress__

BiBTeXML is a pure-perl efficient parser and interpreter for [BibTeX](http://www.bibtex.org) `.bib` and `.bst` files. 

As such it can:
* read BibTeX `.bib` bibliography files
* interpret BibTeX `.bst` bibliography files
* output BiBTeX `.bbl` in a machine-readable format, maintaining source references of substrings


`BiBTeXML` was developed to replace the existing `BiBTeX` handling of [LaTeXML](https://dlmf.nist.gov/LaTeXML/). 
This is where the name comes from -- it does not process any xml.

## Installing BiBTeXML

BiBTeXML requires a sufficiently modern perl (`5.10.1` or above), along with the `Test::More` module. 

Given that `MakeUtils::MakeMaker` is installed, installing BiBTeXML is as follows:

```bash
perl Makefile.PL
make
make test
make install
```

## How it works

BiBTeXML is split into (roughly) four components:

* [`BiBTeXML::Bibliography`](lib/BiBTeXML/Bibliography/) - a parser for `.bib` files
* [`BiBTeXML::BibStyle`](lib/BiBTeXML/BibStyle/) - a parser for `.bst` files
* [`BiBTeXML::Compiler`](lib/BiBTeXML/Compiler/) - a compiler for `.bst` files into perl
* [`BiBTeXML::Runtime`](lib/BiBTeXML/Runtime/) - a runtime for the compiler-generated code (__work in progress__)

## LICENSE

BiBTeXML is free software and released into the public domain according to CC0, see also [LICENSE](LICENSE). 