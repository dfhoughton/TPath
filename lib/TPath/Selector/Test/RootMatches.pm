package TPath::Selector::Test::RootMatches;

# ABSTRACT: handles C</~foo~>

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Matches->new( rx => $self->rx ) );
}

=method candidates

Expects node, collection, and index. Returns root node if its value matches has the specified regex.

=cut

sub candidates {
    my ( $self, $n, $c, $i ) = @_;
    my $r = $i->root;
    return $self->node_test( $r, $i ) ? $r : ();
}

__PACKAGE__->meta->make_immutable;

1;
