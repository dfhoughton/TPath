package TPath::Selector::Test::Self;

# ABSTRACT: note to self: analog of dfh.treepath.SelfSelector

use Moose;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

__PACKAGE__->meta->make_immutable;

1;