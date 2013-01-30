package TPath::Selector;

# ABSTRACT : an interface for classes that select nodes from a candidate collection

use Moose::Role;

=method select

Takes a node an an index and returns a collection of nodes.

=cut

requires 'select';

1;

