package TPath::Selector::Parent;

# ABSTRACT: L<TPath::Selector> that implements C<..>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

=method select

Expects a node and an index. Returns the node's parent, if any.

=cut

sub select {
    my ( $self, $n, $i ) = @_;
    return $n == $i->root ? () : $i->f->parent( $n, $i );
}

__PACKAGE__->meta->make_immutable;

1;

