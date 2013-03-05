package TPath::Selector::Test::Root;

# ABSTRACT: handles C</.>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

=method candidates

Expects node and index. Returns root node.

=cut

sub candidates {
    my ( $self, undef, $i ) = @_;
    return $i->root;
}

__PACKAGE__->meta->make_immutable;

1;
