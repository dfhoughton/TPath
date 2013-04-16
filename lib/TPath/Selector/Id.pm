package TPath::Selector::Id;

# ABSTRACT: C<TPath::Selector> that implements C<id(foo)>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

has id => ( isa => 'Str', is => 'ro', required => 1 );

# required by TPath::Selector
sub select {
    my ( $self, $ctx ) = @_;
    my $n = $ctx->i->indexed->{ $self->id };
    $ctx->bud($n) // ();
}

sub to_string {
    my $self = shift;
    return ':id(' . $self->_escape( $self->id, ')' ) . ')';
}

__PACKAGE__->meta->make_immutable;

1;

