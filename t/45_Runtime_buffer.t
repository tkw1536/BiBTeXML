use BiBTeXML::Common::Test;
use Test::More tests => 3;
use File::Spec;

subtest "requirements" => sub {
    plan tests => 1;

    use_ok("BiBTeXML::Runtime::Buffer");
};

sub makeBuffer {
    my $text = shift(@_);
    open( my $handle, '>', $text );
    return BiBTeXML::Runtime::Buffer->new( $handle, @_ );
}

subtest "wrapEnabled=0" => sub {
    plan tests => 1;

    my $text   = '';
    my $buffer = makeBuffer( \$text, 0 );

    $buffer->write(
        slurp( File::Spec->catfile( 't', 'fixtures', 'buffer', 'input.txt' ) )
    );
    $buffer->finalize;

    is(
        $text,
        slurp(
            File::Spec->catfile(
                't', 'fixtures', 'buffer', 'output_nowrap.txt'
            )
        )
    );
};

subtest "wrapEnabled=1" => sub {
    plan tests => 1;

    my $text   = '';
    my $buffer = makeBuffer( \$text, 1 );

    $buffer->write(
        slurp( File::Spec->catfile( 't', 'fixtures', 'buffer', 'input.txt' ) )
    );
    $buffer->finalize;

    is(
        $text,
        slurp(
            File::Spec->catfile( 't', 'fixtures', 'buffer', 'output_wrap.txt' )
        )
    );
};
