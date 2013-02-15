package TPath::Selector::Test::Child;

# ABSTRACT: handles C</*> where this is not the first step in the path, or C<child::*>

use feature 'state';
use Moose;
use TPath::Test::Node::True;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has tag => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
    my $self = shift;
    state $nt = TPath::Test::Node::True->new;
    $self->_node_test( $nt );
}

=method candidates

Expects node, collection, and index. Returns all child nodes.

=cut

sub candidates {
    my ( $self, $n, $c, $i ) = @_;
    return $i->f->_children( $n, $self->node_test, $i );
}

__PACKAGE__->meta->make_immutable;

1;
