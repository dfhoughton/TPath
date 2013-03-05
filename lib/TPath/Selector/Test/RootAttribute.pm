package TPath::Selector::Test::RootAttribute;

# ABSTRACT: handles C</@foo>

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
    my ( $self, undef, $i ) = @_;
    my $r = $i->root;
    return $self->node_test->passes( $r, $i ) ? $r : ();
}

__PACKAGE__->meta->make_immutable;

1;
