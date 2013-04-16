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

# required by TPath::Test::Node
sub passes {
    my ( $self, $ctx ) = @_;
    return $ctx->i->f->has_tag( $ctx->n, $self->tag );
}

__PACKAGE__->meta->make_immutable;

1;
