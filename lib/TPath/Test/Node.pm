package TPath::Test::Node;

# ABSTRACT: role for tests determining whether a node has some property

=head1 DESCRIPTION

C<TPath::Test::Node> is the interface for objects testing whether a node has
some property. It is not to be confused with L<TPath::Test>. C<TPath::Test::Node>
implements the C<foo> portion of C<//foo[@a or @b]>. C<TPath::Test> implements the
C<@a or @b> portion. Their tests have different signatures.

=cut

use Moose::Role;

=head1 REQUIRED METHODS

=head2 passes

Expects a node and an index and returns whether the node passes its test.

=cut

requires 'passes';

1;
