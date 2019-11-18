# /=====================================================================\ #
# |  BiBTeXML::Runtime::Names                                           | #
# | Runtime name parsing / processing functions                         | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #
package BiBTeXML::Runtime::Names;
use strict;
use warnings;

use BiBTeXML::Runtime::Strings;

use base qw(Exporter);
our @EXPORT = qw(
  &splitNames &numNames
  &splitNameParts &splitNameWords
  &abbrevName &formatNamePart &formatName
);

###
### Splitting a list of names
###

# splits a string into a list of names
# used for numNames and a couple of other utility functions
sub splitNames {
    my ($string) = @_;

    my $level  = 0;
    my $buffer = '';
    my @result = ('');
    my @cache;
    my $character;

    # accumalate entries inside of a buffer
    # and then split the buffer, once we reach a non-zero level
    my @characters = split( //, $string );
    while ( defined( $character = shift(@characters) ) ) {
        if ( $level eq 0 ) {
            $buffer .= $character;
            if ( $character eq '{' ) {
                @cache = split( /\sand\s/, $buffer );
                $result[-1] .= shift(@cache);
                push( @result, @cache );

                # clear the buffer
                $buffer = '';
                $level++;
            }
        }
        else {
            $level++ if $character eq '{';
            $level-- if $character eq '}';

            # because we do not split
            # do not add to the buffer but into the last character
            $result[-1] .= $character;
        }
    }

    # split the buffer and put it into result
    if ($buffer) {
        @cache = split( /\sand\s/, $buffer );
        $result[-1] .= shift(@cache);
        push( @result, @cache );
    }

    # and return the results
    return @result;
}

# count the number of names inside of $string
# i.e. the number of times the word 'and' appears surrounded by spaces
# at brace level 0
# implements num.names$
sub numNames {
    return scalar( splitNames(@_) );
}

###
### Splitting a single name
###

# splits a single name into parts (first, von, jr, last)
# uses the BiBTeX name location
sub splitNameParts {
    my ($string) = @_;

    # split the name into words
    my ( $pre, $mid, $post ) = splitNameWords($string);
    my @prec  = @$pre;
    my @midc  = @$mid;
    my @postc = @$post;

    # prepare all the parts
    my @first = ();
    my @von   = ();
    my @jr    = ();
    my @last  = ();

    # start by splitting off everything except for 'von Last'
    # which we will both store in @von for now (and split below)
    my $word;
    my $gotlower = 0;

    # Style (i): "First von Last"
    if ( scalar(@midc) eq 0 && scalar(@postc) eq 0 ) {

        # if we only have upper case letters, they are all last names
        while ( defined( $word = shift(@prec) ) ) {

            # if we encounter a lower-case, everything before that is first name
            # and everything including and after it is "von Last"
            if ( getCase($word) eq 'l' ) {
                $gotlower = 1;
                @first    = @von;
                @von      = ( $word, @prec );
                last;
            }
            push( @von, $word );
        }

        # if we did not get any lower-case words
        # then the last word is the last name
        # and the rest the first name.
        unless ($gotlower) {
            @first = @von;
            @von   = pop(@first);
        }

        # we did not get any words in the 'von Last' part
        # so that the last of the first name
        if ( scalar(@von) eq 0 ) {
            push( @von, pop(@first) );
        }

        # Style (ii): "von Last, First"
    }
    elsif ( scalar(@postc) eq 0 ) {
        @von   = @prec;
        @first = @midc;

        # Style (iii): "von Last, Jr, First"
    }
    else {
        @von   = @prec;
        @jr    = @midc;
        @first = @postc;
    }

    my $haslast = 0;

    # we now split the "von Last" part
    while ( $word = pop(@von) ) {

        # find the last small word and push it into last
        if ( $haslast && getCase($word) eq 'l' ) {
            push( @von, $word );
            last;

            # push all the big words from 'von' into 'last'
        }
        else {
            unshift( @last, $word );
            $haslast = 1;
        }
    }

    # If the Last part follows the '-' character
    # then that part belongs to the last part too
    if ( scalar(@von) eq 0 && scalar(@last) > 0 ) {
        while ( scalar(@first) && substr( $first[-1], -1, 1 ) eq '-' ) {
            $last[0] = pop(@first) . $last[0];
        }
    }

    return [@first], [@von], [@jr], [@last];
}

# splits a single name into three lists
# one before all commas, one after the first one, one after the second one
sub splitNameWords {
    my ($string) = @_;

    my $level  = 0;
    my $buffer = '';
    my @result = ('');
    my @cache;
    my $character;

    my @characters = split( //, $string );
    while ( defined( $character = shift(@characters) ) ) {
        if ( $level eq 0 ) {
            $buffer .= $character;
            if ( $character eq '{' ) {
                @cache = split( /[\s~-]+\K/, $buffer )
                  ;    # use '\K' to split right *after* the match
                $result[-1] .= shift(@cache);
                push( @result, @cache );

                # clear the buffer
                $buffer = '';
                $level++;
            }
        }
        else {
            $level++ if $character eq '{';
            $level-- if $character eq '}';

            # because we do not split
            # do not add to the buffer but into the last character
            $result[-1] .= $character;
        }
    }

    # split the buffer and put it into result
    if ($buffer) {
        @cache = split( /[\s~-]+\K/, $buffer )
          ;    # use '\K' to split right *after* the match
        $result[-1] .= shift(@cache);
        push( @result, @cache );
    }

    my @precomma  = ();
    my @midcomma  = ();
    my @postcomma = ();
    my $pastcomma = 0;

    # iterate over our result array
    # and pop into the three appropriate lists
    my $seperator;
    while ( defined( $buffer = shift(@result) ) ) {

        # split off everything except for the first seperator
        $buffer =~ s/([\s~-])[\s~-]*$/$1/;

        # we did not yet have a comma
        # so push everything into the first array
        # until we encounter a comma
        if ( $pastcomma eq 0 ) {
            if ( $buffer =~ /,\s+$/ ) {
                $buffer =~ s/,\s+$//;
                push( @precomma, $buffer ) if length($buffer) > 0;
                $pastcomma++;
            }
            else {
                push( @precomma, $buffer );
            }

            # we had one comma
        }
        elsif ( $pastcomma eq 1 ) {
            if ( $buffer =~ /,\s+$/ ) {
                $buffer =~ s/,\s+$//;
                push( @midcomma, $buffer ) if length($buffer) > 0;
                $pastcomma++;
            }
            else {
                push( @midcomma, $buffer );
            }

            # we had a third comma
        }
        else {
            push( @postcomma, $buffer );
        }
    }

    # and return the results
    return [@precomma], [@midcomma], [@postcomma];
}

###
### Formatting a name
###

# abbreviates a name
sub abbrevName {
    my ($string) = @_;
    my ( $letters, $levels ) = splitLetters($string);

    my ( $letter, $isAccent );
    while ( defined( $letter = shift(@$letters) ) ) {

        # if it is an accent, return the letter as a whole
        ($isAccent) = parseAccent($letter);
        return $letter if $isAccent;

        # else, return the first letter of it
        if ( $letter =~ /[a-z]/i ) {
            ($letter) = ( $letter =~ m/([a-z])/i );
            return $letter;
        }
    }

    # we got no letter at all
    # not sure what to return here
    return undef;
}

# formats a single name part according to a specification by BibTeX
sub formatNamePart {
    my ( $parts, $short, $seperator, $post ) = @_;
    my $result = '';

    # if we have an explicit seperator, use it
    # and trim off all the existing ones
    if ( defined($seperator) ) {
        my @names =
          map { my $name = $_; $name =~ s/([\s~-]+)$//; $name; } @$parts;
        @names = map { abbrevName($_) } @names if $short;
        $result = join( $seperator, @names );
    }
    else {
        my ( $name, $seperator, $index ) = ( '', '', 0 );
        my $lastIndex = scalar(@$parts) - 1;

        # iterate through all the names
        foreach $name (@$parts) {

            # extract name and seperator
            ($seperator) = ( $name =~ m/([\s~-]+)$/ );
            $seperator = ' '
              unless defined($seperator)
              ;    # if a seperator is missing, assume it is ' ' just to be safe
            $name =~ s/([\s~-]+)$//;

            # add the current token to the result
            $result .= $short ? abbrevName($name) : $name;
            $result .= '.' if ( $short && $index ne $lastIndex );

# first index (if we have at least three tokens, and the first one is 1 or 2 characters)
            if (   $index eq 0
                && $lastIndex >= 2
                && textLength($name) <= 2 )
            {
                $result .=
                  ( $seperator =~ m/^(\s+)$/ )
                  ? '~'
                  : substr( $seperator, 0, 1 );

                # insert a '~' for the next to last token
            }
            elsif ( $index eq $lastIndex - 1 ) {
                $result .=
                  ( $seperator =~ m/^(\s+)$/ )
                  ? '~'
                  : substr( $seperator, 0, 1 );

                # all non-final tokens: insert the (first) seperator token
            }
            elsif ( $index ne $lastIndex ) {
                $result .= substr( $seperator, 0, 1 );
            }

            $index++;
        }
    }

    # if we end with '~~', end with a single '~'
    if ( $post =~ /~~$/ ) {
        $post =~ s/~~$/~/;

        # if we end with non-double ~, end with a space
    }
    elsif ( $post =~ /~$/ ) {
        $post =~ s/~$/ /;
    }
    return $result . $post;
}

# formats a BiBTeX name according to a specification
# implements format.name$
sub formatName {
    my ( $name, $spec ) = @_;

    # split the name into pieces, we will need this during formatting
    my ( $first, $von, $jr, $last ) = splitNameParts($name);
    my @currp;

    # the specification, split into characters
    my @characters = split( //, $spec );
    my ( $result, $partresult, $character );
    my ( $letter, $short, $seperator, $post );
    my ($level);

    while ( defined( $character = shift(@characters) ) ) {

        if ( $character eq '{' ) {

            # iterate through the subpattern
            $partresult = '';
            while ( $character = shift(@characters) ) {

                # we finally hit the alphabetic character
                if ( $character =~ /[a-z]/i ) {
                    $letter = $character;

                    # check which part we have
                    if ( $letter eq 'f' ) {
                        @currp = @$first;
                    }
                    elsif ( $letter eq 'v' ) {
                        @currp = @$von;
                    }
                    elsif ( $letter eq 'j' ) {
                        @currp = @$jr;
                    }
                    elsif ( $letter eq 'l' ) {
                        @currp = @$last;
                    }
                    else {
                        return undef, 'Invalid name part: ' . $letter;
                    }

                    # read the next pattern
                    $character = shift(@characters);
                    return undef, 'Unexpected end of pattern'
                      unless defined($character);

                    # if we have the letter repeated, it is a long pattern
                    if ( $character =~ /[a-z]/i ) {
                        return undef,
"Unexpected letter $character, $letter should be repeated. "
                          unless $character eq $letter;
                        $short     = 0;
                        $character = shift(@characters);
                        return 'Unexpected end of pattern'
                          unless defined($character);

                        # else if must be a short pattern.
                    }
                    else {
                        $short = 1;
                    }

                    # if we have a '{', read the seperator
                    $seperator = undef;
                    if ( $character eq '{' ) {
                        $level     = 1;
                        $seperator = '';
                        while ( defined( $character = shift(@characters) ) ) {
                            $level++ if $character eq '{';
                            $level-- if $character eq '}';
                            last     if $level eq 0;
                            $seperator .= $character;
                        }
                    }
                    else {
                        unshift( @characters, $character );
                    }

                    # read whatever comes next until we are balaned again
                    # until the closing '}' brace
                    $post  = '';
                    $level = 1;
                    while ( defined( $character = shift(@characters) ) ) {
                        $level++ if $character eq '{';
                        $level-- if $character eq '}';
                        last     if $level eq 0;
                        $post .= $character;
                    }

                    # now format the current part according to what we read.
                    if ( scalar(@currp) eq 0 ) {
                        $partresult = '';
                    }
                    else {
                        my $r =
                          formatNamePart( [@currp], $short, $seperator, $post );
                        $partresult .= $r;
                    }
                    last;

                    # if we closed the part, without having anything alphabetic
                    # then something weird is going on, so insert it literally.
                }
                elsif ( $character eq '}' ) {
                    $partresult = '{' . $partresult . '}';
                    last;

                    # if we do not have a letter
                    # insert this part literally
                }
                else {
                    $partresult .= $character;
                }
            }
            $result .= $partresult;

            # outside of a group
            # characters are inserted undonditionally
        }
        else {
            $result .= $character;
        }
    }

    return $result;
}

1;
