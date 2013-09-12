package TPath::Selector::Test::ClosestMatch;

# ABSTRACT: handles C</E<gt>~foo~>

use Moose;
use TPath::Test::Node::Match;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test::Match';

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Match->new( rx => $self->rx ) );
}

# implements method required by TPath::Selector::Test
sub candidates {
    my ( $self, $ctx, $first ) = @_;
    return $ctx->i->f->closest( $ctx, $self->node_test, !$first );
}
sub to_string {
    my $self = shift;
    return
        '/>'
      . ( $self->is_inverted ? '^' : '' )
      . $self->_stringify_match( $self->val );
}

__PACKAGE__->meta->make_immutable;

1;
