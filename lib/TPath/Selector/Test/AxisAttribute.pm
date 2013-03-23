package TPath::Selector::Test::AxisAttribute;

# ABSTRACT: handles C</ancestor::@foo> or C</preceding::@foo> where this is not the first step in the path, or C<ancestor::@foo>, etc.

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
	my $nt = TPath::Test::Node::Attribute->new( a => $self->a );
	$self->_node_test($nt);
}

__PACKAGE__->meta->make_immutable;

1;
