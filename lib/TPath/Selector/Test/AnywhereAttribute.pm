package TPath::Selector::Test::AnywhereAttribute;

# ABSTRACT: handles C<//@foo> expression

use Moose;
use TPath::Test::Node::Attribute;
use TPath::TypeConstraints;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;
    $class->$orig(
        %args,
        first_sensitive => 1,
        axis            => 'descendant',
    );
};

sub BUILD {
    my $self = shift;
    my $nt = TPath::Test::Node::Attribute->new( a => $self->a );
    $self->_node_test($nt);
}

sub to_string {
    my $self = shift;
    '//' . ( $self->is_inverted ? '^' : '' ) . $self->a->to_string;
}

__PACKAGE__->meta->make_immutable;

1;
