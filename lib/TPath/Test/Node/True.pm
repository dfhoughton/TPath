package TPath::Test::Node::True;

# ABSTRACT: TPath::Test::Node implementing the wildcard; e.g., //*

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Test::Node>

=cut

with 'TPath::Test::Node';

=method passes

Every node passes this test.

=cut

sub passes { 1 }

__PACKAGE__->meta->make_immutable;

1;