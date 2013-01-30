package TPath::Test;

# ABSTRACT : interface conditional expressions in predicates

use Moose::Role;

=method filter

Takes a node, a collection of nodes, and an index and returns whether the node
passes the predicate.

=cut

requires 'test';

1;
