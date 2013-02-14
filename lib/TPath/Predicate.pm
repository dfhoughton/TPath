package TPath::Predicate;

# ABSTRACT: interface of square bracket sub-expressions in TPath expressions

use Moose::Role;

=method filter

Takes a collection of nodes and an index and returns the collection of nodes
for which the predicate is true.

=cut

requires 'filter';

1;
