package TPath::Selector::Test::ChildAttribute;

# ABSTRACT: handles C</@foo> where this is not the first step in the path, or C<child::@foo>

use Moose;
use TPath::Test::Node::Attribute;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Attribute->new( a => $self->a ) );
}

=method candidates

Expects node and index. Returns root node if it has the specified tag.

=cut

sub candidates {
    my ( $self, $n, $i ) = @_;
    return $i->f->_children( $n, $self->node_test, $i );
}

__PACKAGE__->meta->make_immutable;

1;
