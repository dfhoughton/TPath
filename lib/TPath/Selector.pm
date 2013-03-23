package TPath::Selector;

# ABSTRACT: an interface for classes that select nodes from a candidate collection

use Moose::Role;

=attr

Whether the selector should be regarded as consuming "firstness" even if it returns
its context node.

=cut

has consumes_first => ( is => 'ro', isa => 'Bool', default => 1 );

=head1 REQUIRED METHODS

=head2 select

Takes a node, an index, and whether the selection concerns the initial node
and returns a collection of nodes.

=cut

requires 'select';

1;

