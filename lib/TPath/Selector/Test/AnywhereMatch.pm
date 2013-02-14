package TPath::Selector::Test::AnywhereMatch;

# ABSTRACT: handles C<//~foo~> expression

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has first => ( is => 'ro', isa => 'Bool', required => 1 );

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

sub BUILD {
    my $self = shift;
    my $nt = TPath::Test::Node::Matches->new( rx => $self->rx );
    $self->_node_test($nt);
    my $axis = $self->first ? 'descendant-or-self' : 'descendant';
    $self->_axis($axis);
}

__PACKAGE__->meta->make_immutable;

1;
