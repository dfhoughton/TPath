package TPath::Test::Node::Tag;

# ABSTRACT: L<TPath::Test::Node> implementing basic tag pattern; e.g., C<//foo>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr tag

Tag or value to match.

=cut

has tag => ( is => 'ro', isa => 'Str', required => 1 );

=method passes

Nodes having the right tag pass.

=cut

sub passes {
    my ( $self, $n, $i ) = @_;
    return $i->f->has_tag( $n, $self->tag );
}

__PACKAGE__->meta->make_immutable;

1;
