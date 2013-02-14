package TPath::Test::Node::Matches;

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

=method passes

Nodes bearing a value that matches the pattern pass.

=cut

sub passes {
    my ( $self, $n, $i ) = @_;
    return $i->f->matches_tag( $n, $self->rx );
}

__PACKAGE__->meta->make_immutable;

1;
