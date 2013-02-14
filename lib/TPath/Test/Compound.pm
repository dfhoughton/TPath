package TPath::Test::Compound;

# ABSTRACT : role of TPath::Tests that combine multiple other tests under some boolean operator

use Moose::Role;

=head1 ROLES

L<TPath::Test::Boolean>

=cut

with 'TPath::Test::Boolean';

=attr tests

Subsidiary L<TPath::Test> objects combined by this test.

=cut

has tests => ( is => 'ro', isa => 'ArrayRef[TPath::Test]', required => 1 );

1;