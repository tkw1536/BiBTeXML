# /=====================================================================\ #
# |  BiBTeXML::Compiler::Target                                         | #
# | abstract base class for compiler targets                            | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Compiler::Target;
use strict;
use warnings;

### A Compiler Target serves as an abstraction for the different kinds of output the bst AST can be compiled to.
### This file does not do any compilation, instead it serves as documentation to implement your own.
### all functions should return plain perl strings, that are concatinatable with newlines to produce the final output

# makeIndent($level) - make indent of a given level
# - $indent:   integer, indicating level of indent to make
sub makeIndent { die("Unimplemented"); }

# escapeBuiltinName($name) - escapes the name of a built-in function
# - $name:  the name of the function to be escaped
sub escapeBuiltinName { die("Unimplemented"); }

# escapeFunctionName($name) - escapes the name of a user-defined function
# - $name:  the name of the function to be escaped
sub escapeFunctionName { die("Unimplemented"); }

# escapeString($string) - escapes a string constant
# - $string:    the string to be escaped
sub escapeString { die("Unimplemented"); }

# escapeInteger($name) - escapes an integer
# - $integer:    the integer to be escaped
sub escapeInteger { die("Unimplemented"); }

# escapeFunctionReference($name) - escapes the reference to a bst-level function
# - $name:    the (escaped) name of the bst function to call
sub escapeBstFunctionReference { die("Unimplemented"); }

# escapeBstInlineBlock($block, $sourceString, $outerIndent, $innerIndent) - escapes the definition of a bst-inline block
# - $block:         the (compiled) body of the block to define
# - $sourceString:  the StyString this inline function was defined from
# - $outerIndent:   the (generated) outer indent, for use in multi-line outputs
# - $innerIndent:   the (generated) inner indent, for use in multi-line outputs
sub escapeBstInlineBlock { die("Unimplemented"); }

# bstFunctionDefinition($name, $sourceString, $body, $outerIndent, $innerIndent) - escapes the definition to a bst function
# - $name:          the (escaped) name of the bst function to define
# - $sourceString:  the StyString this function was defined from
# - $body:          the (compiled) body of the function to define
# - $outerIndent:   the (generated) outer indent, for use in multi-line outputs
# - $innerIndent:   the (generated) inner indent, for use in multi-line outputs
sub bstFunctionDefinition { die("Unimplemented"); }

# bstFunctionCall($name, $sourceString, @argument) - compiles a call to a bst-level function
# - $name:          the name of the bst function to call
# - $sourceString:  the StyString this call was made from
# - @arguments:     a set of appropriatly escaped arguments to give to the call
sub bstFunctionCall { die("Unimplemented"); }

# runtimeFunctionCall($name, $sourceString, @arguments) - compiles a call to function in the runtime
# - $name:          the name of the runtime function to call
# - $sourceString:  the StyString this call was made from
# - @arguments:     a set of appropriatly escaped arguments to give to the call
sub runtimeFunctionCall { die("Unimplemented"); }

# wrapProgram($program, $name) - function used to wrap a compiled program
# - $program:      the compiled program
# - $name:         the (string escaped) file name of the program to be compiled
sub wrapProgram { die("Unimplemented"); }

### Some general notes:
### - references to entry fields + variables and global variables are always treated as strings
### - references to functions (builtin + user-defined) are treated equally as target-language functions
### - at any point behind a finished instruction, a newline might be added by the compiler
### - the default indent level is indent level 0, however it is set to 1 inside the main program

### A Compiler Runtime function is a function of the runtime that implements a specific behavior.
### These are listed for completion here, but do not have any direct Compile::Target treatment
###
### Runtimes are free to define additional parameters (like a global $context or $state) to
### pass to each function, however these should be handled with
### bstFunctionCall, runtimeFunctionCall, bstFunctionDefinition and escapeBstInlineBlock
### accordingly.

###
### Definining things
###

# defineEntryField($name) -- defines a new entry field
# - $name:     string containing name of the field to define

# defineEntryInteger($name) -- defines a new entry integer
# - $name:     string containing name of the integer to define

# defineEntryString($name) -- defines a new entry string
# - $name:     string containing name of the string to define

# defineGlobalString($name) -- defines a new global string
# - $name:     string containing name of the string to define

# defineGlobalInteger($name) -- defines a new global integer
# - $name:     string containing name of the integer to define

# defineMacro($name, $value) -- defines a new macro
# - $name:     string containing the name of the macro to define
# - $value:    string containing the value of the macro to define

###
### Reading and iterating over items
###

# readEntries() -- reads all entries from the appropriate .bib file(s)

# sortEntries() -- sorts (already read) entries

# iterateFunction($function) -- iterates a function over all entries
# - $function:  function reference to be iterated over all entries

# reverseFunction($function) -- iterates a function (or builtin) over all (read) entries in reverse
# - $function:  function reference to be iterated over all entries

###
### Pushing constants onto the stack
###

# pushString($string) -- pushes a string onto the stack
# - $string: string to push onto the stack

# pushInteger($integer) -- pushes an integer onto the stack
# - $integer: integer to push onto the stack

###
### Pushing references to things onto the stack
###

# pushFunction($block) -- pushes a function (i.e. inline block) onto the stack
# - $block:  inline block to push

# pushGlobalString($name) -- pushes a global string onto the stack
# - $name:  name of the global string to push

# pushGlobalInteger($name) -- pushes a global integer onto the stack
# - $name:  name of the global integer to push

# pushEntryField($name) -- pushes an entry field onto the stack
# - $name:  name of the entry field to push

# pushEntryString($name) -- pushes an entry string onto the stack
# - $name:  name of the entry string to push

# pushEntryInteger($name) -- pushes an entry integer onto the stack
# - $name:  name of the entry integer to push

###
### Pushing values of things onto the stack
###

# lookupGlobalString($name) -- pushes the value of a global string onto the stack
# - $name:  name of the global string

# lookupGlobalInteger($name) -- pushes the value of a integer onto the stack
# - $name:  name of the global integer

# lookupEntryField($name) -- pushes the value of an entry field onto the stack
# - $name:  name of the entry field

# lookupEntryString($name) -- pushes the value of an entry string onto the stack
# - $name:  name of the entry string

# lookupEntryInteger($name) -- pushes the value of an entry integer onto the stack
# - $name:  name of the entry integer

1;
