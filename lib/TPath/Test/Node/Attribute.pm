package TPath::Test::Node::Attribute;

# ABSTRACT: L<TPath::Test::Node> implementing matching; e.g., C<//~foo~>

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=attr a

Attribute to detect.

=cut

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

# required by TPath::Test::Node
sub passes {
    my ( $self, $n, $i ) = @_;
    return $self->a->test( $n, [], $i ) ? 1 : undef;
}

__PACKAGE__->meta->make_immutable;

1;
