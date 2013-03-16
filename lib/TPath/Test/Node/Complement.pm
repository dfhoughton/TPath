package TPath::Test::Node::Complement;

# ABSTRACT: L<TPath::Test::Node> implementing matching; e.g., C<//^~foo~>, C<//^foo>, and C<//^@foo>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr a

Attribute to detect.

=cut

has nt => ( is => 'ro', isa => 'TPath::Test::Node', required => 1 );

# required by TPath::Test::Node
sub passes {
    my ( $self, $n, $i ) = @_;
    return $self->nt->passes( $n, $i ) ? undef : 1;
}

__PACKAGE__->meta->make_immutable;

1;
