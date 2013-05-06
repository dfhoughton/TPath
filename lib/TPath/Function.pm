package TPath::Function;

# ABSTRACT: implements the functions in expressions such as C<//*[:abs(@foo) = 1]> and C<//*[:sqrt(@bar) == 2]>

use Moose;

with 'TPath::Numifiable';

has f => ( is => 'ro', isa => 'CodeRef', required => 1 );

has name => ( is => 'ro', isa => 'Str', required => 1 );

has arg => ( is => 'ro', isa => 'TPath::Numifiable', required => 1 );

sub to_num {
    my ( $self, $ctx ) = @_;
    return $self->f->( $self->arg->to_num($ctx) );
}

sub to_string {
    my $self = shift;
    my $s    = ':' . $self->name . '(';
    if ( $self->arg->isa('TPath::Math') ) {
        $s .= ' ' . $self->arg->to_string(1) . ' ';
    }
    else {
        $s .= $self->arg->to_string(1);
    }
    $s .= ')';
    return $s;
}

1;
