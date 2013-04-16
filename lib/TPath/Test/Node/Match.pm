package TPath::Test::Node::Match;

# ABSTRACT: L<TPath::Test::Node> implementing matching; e.g., C<//~foo~>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr rx

Pattern to match.

=cut

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

# required by TPath::Test::Node
sub passes {
    my ( $self, $ctx ) = @_;
    return $ctx->i->f->matches_tag( $ctx->n, $self->rx );
}

__PACKAGE__->meta->make_immutable;

1;
