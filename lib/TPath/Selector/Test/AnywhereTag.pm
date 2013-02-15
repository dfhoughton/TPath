package TPath::Selector::Test::AnywhereTag;

# ABSTRACT: handles C<//foo> expression

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has first => ( is => 'ro', isa => 'Bool', required => 1 );

has tag => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
    my $self = shift;
    my $nt = TPath::Test::Node::Tag->new( tag => $self->tag );
    $self->_node_test( $nt );
    my $axis = $self->first ? 'descendant-or-self' : 'descendant';
    $self->_axis($axis);
}

__PACKAGE__->meta->make_immutable;

1;
