package TPath::Selector::Test::ClosestTag;

# ABSTRACT: handles C</E<gt>foo>

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has tag => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Tag->new( tag => $self->tag ) );
}

# required by TPath::Selector::Test
sub candidates {
    my ( $self, $ctx, $first ) = @_;
    return $ctx->i->f->closest( $ctx, $self->node_test, !$first );
}

sub to_string {
    my $self = shift;
    return
        '/>'
      . ( $self->is_inverted ? '^' : '' )
      . $self->_stringify_label( $self->tag );
}

__PACKAGE__->meta->make_immutable;

1;
