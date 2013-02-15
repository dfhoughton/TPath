package TPath::Test::Compound;

# ABSTRACT: role of TPath::Tests that combine multiple other tests under some boolean operator

use Moose::Role;
use TPath::TypeConstraints;

=head1 ROLES

L<TPath::Test::Boolean>

=cut

with 'TPath::Test::Boolean';

=attr tests

Subsidiary L<TPath::Test> objects combined by this test.

=cut

has tests => ( is => 'ro', isa => 'ArrayRef[CondArg]', required => 1 );

1;