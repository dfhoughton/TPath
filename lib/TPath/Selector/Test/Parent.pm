package TPath::Selector::Test::Parent;

# ABSTRACT: handles C<..>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

=method candidates

Expects node, collection, and index. Returns parent of current node.

=cut

sub candidates {
    my ( $self, $n, $c, $i ) = @_;
    return $n == $i->root ? () : $i->f->parent( $n, $i );
}

__PACKAGE__->meta->make_immutable;

1;
