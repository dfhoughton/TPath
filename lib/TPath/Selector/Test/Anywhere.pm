package TPath::Selector::Test::Anywhere;

# ABSTRACT: handles C<//*> expression

use feature 'state';
use Moose;
use TPath::Test::Node::True;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has first => ( is => 'ro', isa => 'Bool', required => 1 );

sub BUILD {
    my $self = shift;
    state $nt = TPath::Test::Node::True->new;
    $self->_node_test( $nt );
    my $axis = $self->first ? 'descendant-or-self' : 'descendant';
    $self->_axis($axis);
}

__PACKAGE__->meta->make_immutable;

1;
