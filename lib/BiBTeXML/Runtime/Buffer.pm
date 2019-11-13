# /=====================================================================\ #
# |  BiBTeXML::Runtime::Buffer                                          | #
# | Emulates BiBTeX's buffer implementation                             | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Buffer;
use strict;
use warnings;

# creates a new output buffer used by BiBTeX
# only enables
sub new {
    my ( $class, $handle, $wrapEnabled ) = @_;

    return bless {

        # handle to send output to
        handle => $handle,

        wrapEnabled => $wrapEnabled,
        breakAfter  => 79,

        # state for
        counter => 0,     # counter for the current line
        buffer  => "",    # current internal buffer
        skipSpaces =>
          0,    # flag to indicate if whitespace is currently being skipped
    }, $class;
}

# Write writes a string from the buffer to the output handle
# and emulates BibTeX's hard-wrapping
sub write {
    my ( $self, $string, $source ) = @_;
    my @chars = split( "", $string );
    my ($char);
    foreach $char (@chars) {

        # if we need to skip spaces, don't output anything
        next if $$self{skipSpaces} && ( $char =~ /\s/ );

        # increase the counter and reset skipSpaces
        $$self{skipSpaces} = 0;
        $$self{counter}++;

        # character is a newline => reset the counter
        if ( $char eq "\n" ) {
            $$self{buffer} =~ s/\s+$//;    # trim right-most spaces
            print { $$self{handle} } $$self{buffer} . "\n";
            $$self{buffer}  = '';
            $$self{counter} = 0;

            # we had too many characters and there is a space
        }
        elsif ($$self{wrapEnabled}
            && ( $$self{counter} >= $$self{breakAfter} )
            && ( $char =~ /\s/ ) )
        {
            $$self{buffer} =~ s/\s+$//;    # trim right-most spaces
            print { $$self{handle} } $$self{buffer} . "\n  ";
            $$self{buffer}     = '';
            $$self{counter}    = 2;
            $$self{skipSpaces} = 1;

        }
        else {
            $$self{buffer} .= $char;
        }
    }
}

# finalize closes this buffer and flushes whatever is left in the buffer to STDOUT
sub finalize {
    my ($self) = @_;

    # print whatever is left in the handle to the buffer
    print { $$self{handle} } $$self{buffer};

    # state reset (not really needed, buf whatever)
    $$self{buffer}     = '';
    $$self{counter}    = 0;
    $$self{skipSpaces} = 0;

    close( $$self{handle} );
}

1;
