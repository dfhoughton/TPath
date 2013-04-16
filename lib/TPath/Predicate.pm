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

1;
