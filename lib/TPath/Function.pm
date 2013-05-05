package TPath::Function;

# ABSTRACT: implements the functions in expressions such as C<//*[:abs(@foo) = 1]> and C<//*[:sqrt(@bar) == 2]>

use Moose;

with 'TPath::Numifiable';

has f => ( is => 'ro', isa => 'CodeRef', required => 1 );

has name => ( is => 'ro', isa => 'Str', required => 1 );

has arg => ( is => 'ro', isa => 'TPath::Numifier', required => 1 );

sub to_num {
    my ( $self, $ctx ) = @_;
    return $self->f->( $self->arg->to_num($ctx) );
}

sub to_string {
    my $self = shift;
    return ':', $self->name . '(' . $self->arg->to_string(1) . ')';
}

1;
