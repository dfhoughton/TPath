package TPath::Selector::Test::ClosestAttribute;

# ABSTRACT: handles C</E<gt>@foo>

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

# required by TPath::Selector::Test
sub candidates {
    my ( $self, $n, $i, $first ) = @_;
    return $i->f->closest( $n, $self->node_test, $i, !$first );
}

__PACKAGE__->meta->make_immutable;

1;
