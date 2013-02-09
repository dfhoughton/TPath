package TPath::Selector::Test;

# ABSTRACT : role of selectors that apply some test to a node to select it

=head1 DESCRIPTION

A L<TPath::Selector> that holds a list of L<TPath::Predicate>s.

=cut

use Moose::Role;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

=head1 ATTRIBUTES

=head2 predicates

Auto-deref'ed list of L<TPath::Predicate> objects that filter anything selected
by this selector.

=cut

has predicates => (
    is         => 'ro',
    isa        => 'ArrayRef[TPath::Predicate]',
    default    => sub { [] },
    auto_deref => 1
);

1;
