package TPath::Selector::Test::RootMatch;

# ABSTRACT: handles C</~foo~>

use Moose;
use TPath::Test::Node::Match;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Match->new( rx => $self->rx ) );
}

# required by TPath::Selector::Test
sub candidates {
    my ( $self, $n, $i ) = @_;
    my $r = $i->root;
    return $self->node_test->passes( $r, $i ) ? $r : ();
}

__PACKAGE__->meta->make_immutable;

1;
