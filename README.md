# BiBTeXML

[![Build Status](https://travis-ci.org/tkw1536/BibTeXML.svg?branch=master)](https://travis-ci.org/tkw1536/BibTeXML)

__Still a work in progress__

BiBTeXML is a pure-perl efficient parser, compiler and interpreter for [BibTeX](http://www.bibtex.org) `.bib` and `.bst` files. 

As such it can:
* read BibTeX `.bib` bibliography files
* compile BibTeX `.bst` bibliography style files into perl
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

* [`BiBTeXML::BibStyle`](lib/BiBTeXML/BibStyle/) - a parser for `.bst` files
* [`BiBTeXML::Compiler`](lib/BiBTeXML/Compiler/) - a compiler for `.bst` files into perl (and possibly other languages)

* [`BiBTeXML::Runtime`](lib/BiBTeXML/Runtime/) - a (perl only) runtime for the compiler-generated code (__work in progress__)
* [`BiBTeXML::Bibliography`](lib/BiBTeXML/Bibliography/) - a parser for `.bib` files

## How to use

BiBTeXML can run it's two different stages, the compilation and runtime, seperatly


### Running the compilation stage

First, the `.bst` needs to be read, and compiled. 
In general, this can be done achieved using `bibtexmlc` ( *c* as in *compile*). 
It has the following syntax:

```
bibtexmlc [--help] [--target $TARGET] [--destination $DEST] $BSTFILE 
```

- `$TARGET` is the name of a specific target class to use. It defaults to `Perl`. The compiler assumes a Target class to be named `BiBTeXML::Compiler::Target::$TARGET`, however this can be overriden if `$TARGET` contains a `:`. 
- `$DEST` is the name of the output file to write output to. If omitted, output is sent to `STDOUT`. 
- `$BSTFILE` is the (absolute or relative to the working directory) path to the `.bst` file to compile. 

All messages and errors are written to STDERR. 

The executable has the following exit codes:
- `0` if everything worked as normal
- `1` if there was trouble parsing command line options
- `2` if there was trouble finding the given target
- `3` if there were problems finding the input file
- `4` if there were problems parsing the file
- `5` if there were problems compiling the file
- `6` if there were was trouble writing the output file 


For example, to compile a .bst file called `plain.bst` using the `Perl` target:

```
bibtexmlc plain.bst --destination plain.bst.pl
```


### Running the runtime stage

(Work in progress)


### See also

For documentation on BiBTeX Style Files, the following resources are helpful:

* [Tame the BeaST](http://mirrors.ctan.org/info/bibtex/tamethebeast/ttb_en.pdf) -- in particular sections 3 + 4
* [Designing BIBTEX Styles](http://mirrors.ctan.org/biblio/bibtex/base/btxhak.pdf) -- a.k.a `texdoc btxhak`
* [Names in BibTEX and MlBibTEX](https://www.tug.org/TUGboat/tb27-2/tb87hufflen.pdf) -- for details on how exactly name parsing works

## LICENSE

BiBTeXML is free software and released into the public domain according to CC0, see also [LICENSE](LICENSE). 