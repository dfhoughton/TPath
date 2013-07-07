package TPath::Concatenation;

# ABSTRACT: handles the string concatenation in C<//@foo[1 ~ @bar ~ "quux"]>

use v5.10;
use Moose;
use TPath::TypeConstraints;
use namespace::autoclean;

with 'TPath::Stringifiable';

has args => ( is => 'ro', isa => 'ArrayRef[ConcatArg]' );

sub concatenate {
    my ( $self, $ctx ) = @_;
    my $s = '';
    for my $arg ( @{ $self->args } ) {
        for ($arg) {
            when ( !blessed $_ )                 { $s .= $_ }
            when ( $_->isa('TPath::Attribute') ) { $s .= $_->apply($ctx) }
            when ( $_->isa('TPath::Math') )      { $s .= $_->to_num($ctx) }
            when ( $_->isa('TPath::Expression') ) {
                $s .= join '', @{ $_->_select( $ctx, 1 ) }
            }
            default { die 'unexpected concatenation argument type: ' . ref $_ }
        }
    }
    return $s;
}

sub to_string {
    my $self      = shift;
    my $s         = '';
    my $non_first = 0;
    for my $arg ( @{ $self->args } ) {
        $s .= ' ~ ' if $non_first++;
        $s .= ref $arg ? $arg->to_string : $self->_stringify($arg);
    }
    return $s;
}

1;
