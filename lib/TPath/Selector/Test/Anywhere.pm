package TPath::Selector::Test::Anywhere;

# ABSTRACT: handles C<//*> expression

use feature 'state';
use Moose;
use TPath::Test::Node::True;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

around BUILDARGS => sub {
	my ( $orig, $class, %args ) = @_;
	state $nt = TPath::Test::Node::True->new;
	$class->$orig(
		%args,
		first_sensitive => 1,
		axis            => 'descendant',
		node_test       => $nt
	);
};

__PACKAGE__->meta->make_immutable;

1;
