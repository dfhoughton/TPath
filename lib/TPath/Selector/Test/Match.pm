package TPath::Selector::Test::Match;

# ABSTRACT: role for all matching selectors

use Moose::Role;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

has val => ( is => 'ro', isa => 'Str', required => 1);

1;
