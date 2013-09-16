package TPath::Test::Node::Attribute;

# ABSTRACT: L<TPath::Test::Node> implementing attributes; e.g., C<//@foo>

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

    # my ( $self, $ctx ) = @_;
    return $_[0]->a->test( $_[1] ) ? 1 : undef;
}

sub to_string { $_[0]->a->to_string }

__PACKAGE__->meta->make_immutable;

1;
