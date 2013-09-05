package TPath::Predicate;

# ABSTRACT: interface of square bracket sub-expressions in TPath expressions

use Moose::Role;

=head1 ROLES

L<TPath::Stringifiable>

=cut

with 'TPath::Stringifiable';

=method filter

Takes an index and  a collection of L<TPath::Context> objects and returns the collection of contexts
for which the predicate is true.

=cut

requires 'filter';

=attr outer

Whether the predicate is inside or outside any grouping parentheses.

  //*[foo]    # inside  -- outer is false
  (//*)[foo]  # outside -- outer is true

This distinction, though available to all predicates, is especially important to index predicates.

  //*[0]

Means the root and any element which is the first child of its parents. While

  (//*)[0]

means the first of all elements -- the root.

=cut

has outer => ( is => 'ro', isa => 'Bool', default => 0 );

1;
