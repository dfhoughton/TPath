package TPath::Selector::Test::Root;

# ABSTRACT: handles C</.>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

=method candidates

Expects node, collection, and index. Returns root node.

=cut

sub candidates {
    my ( $self, $n, $c, $i ) = @_;
    return $i->root;
}

__PACKAGE__->meta->make_immutable;

1;
