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

=method candidates

Expects node, collection, and index. Returns node.

=cut

sub candidates {
    my ( $self, $n, $c, $i ) = @_;
    return $i->f->closest( $n, $self->node_test, $i );
}

__PACKAGE__->meta->make_immutable;

1;
