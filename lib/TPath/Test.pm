package TPath::Test;

# ABSTRACT: interface of conditional expressions in predicates

=head1 DESCRIPTION

Interface of objects expressing tests in predicate expressions. E.g., the C<@a or @b> in 
C<//foo[@a or @b]>. Not to be confused with L<TPath::Test::Node>, which is used to implement
the C<foo> portion of this expression.

=cut

use Moose::Role;

=head1 REQUIRED METHODS

=head2 test

Takes a node, a collection of nodes, and an index and returns whether the node
passes the predicate.

=cut

requires 'test';

1;
