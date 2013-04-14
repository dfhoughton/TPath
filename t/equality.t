# makes sure stringification of an expression is semantically identical to the original

use v5.10;
use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use Test::Exception;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

my ( $path, $p, @elements );

$p        = parse(q{<a><b><aa/></b><b><bb/></b></a>});
$path     = q{//b[@echo(~..~) = @echo(~a~)]};
@elements = $f->path($path)->select($p);
is @elements, 1, "found expected number of elements with $path on $p";
is $elements[0], '<b><aa/></b>', 'found correct element';

{

    package Node;

    sub new {
        shift;
        bless { @_, children => [] };
    }

    sub tag      { $_[0]->{tag} }
    sub children { $_[0]->{children} }
    sub payload  { $_[0]->{payload} }
    sub add      { my $self = shift; push @{ $self->children }, @_; $self }

    sub equals {
        my ( $self, $other ) = @_;
        return $self->tag eq $other->tag
          && eql( $self->payload, $other->payload );
    }

    sub eql {
        my ( $left, $right ) = @_;
        return if defined $left ^ defined $right;
        return 1 unless defined $left;
        my ( $lt, $rt ) = map { ref $_ } $left, $right;
        if ( ref $left eq ref $right ) {
            for ( ref $left ) {
                when ('HASH') {
                    my @k1 = keys %$left;
                    return unless @k1 == keys %$right;
                    for my $k (@k1) {
                        return unless exists $right->{$k};
                        return unless eql( $left->{$k}, $right->{$k} );
                    }
                    return 1;
                }
                when ('ARRAY') {
                    my @a1 = @$left;
                    my @a2 = @$right;
                    return unless @a1 == @a2;
                    for my $i ( 0 .. $#a1 ) {
                        return unless eql( $a1[$i], $a2[$i] );
                    }
                    return 1;
                }
                default { return $left eq $right }
            }
        }
        return;
    }
}

{

    package Forester;
    use Moose;
    use MooseX::MethodAttributes;
    with 'TPath::Forester';

    sub children {
        my ( $self, $n ) = @_;
        @{ $n->{children} };
    }

    sub tag {
        my ( $self, $n ) = @_;
        $n->{tag};
    }

    sub p : Attr {
        my ( undef, $n ) = @_;
        $n->payload;
    }

}

$f = Forester->new;

my $tree = Node->new( tag => 'b', payload => [1] )->add(
    Node->new( tag => 'b', payload => [2] )->add(
        Node->new( tag => 'a', payload => { c => 1 } )
          ->add( Node->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[@echo(.) = @echo(*)]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'a', 'expected tag for element received';
$path     = q{//*[@echo(.) == @echo(*)]};
@elements = $f->path($path)->select($tree);
is @elements, 0, "received expected number of elements with $path";

my $payload = {foo=>'bar'};
$tree = Node->new( tag => 'b', payload => $payload )->add(
    Node->new( tag => 'b', payload => $payload )->add(
        Node->new( tag => 'a', payload => { c => 1 } )
          ->add( Node->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[@at(., 'p') = @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 2, "received expected number of elements with $path";
is $elements[0]->tag, 'a', 'expected tag for first element received';
is $elements[1]->tag, 'b', 'expected tag for first element received';
$path     = q{//*[@at(., 'p') == @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for element received';

done_testing();