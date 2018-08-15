# BiBTeXML

[![Build Status](https://travis-ci.org/tkw1536/BibTeXML.svg?branch=master)](https://travis-ci.org/tkw1536/BibTeXML)

** Still a work in progress **

BiBTeXML is a pure-perl efficient parser and interpreter for [BibTeX](http://www.bibtex.org) `.bib` and `.bst` files. 

As such it can
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

## LICENSE

BiBTeXML is free software and released into the public domain according to CC0, see also [LICENSE](LICENSE). 