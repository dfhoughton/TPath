package TPath::Selector::Test::RootTag;

# ABSTRACT: handles C</foo>

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has tag => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Tag->new( tag => $self->tag ) );
}

=method candidates

Expects node, collection, and index. Returns root node if it has the specified tag.

=cut

sub candidates {
    my ( $self, $n, $c, $i ) = @_;
    my $r = $i->root;
    return $self->node_test( $r, $i ) ? $r : ();
}

__PACKAGE__->meta->make_immutable;

1;
