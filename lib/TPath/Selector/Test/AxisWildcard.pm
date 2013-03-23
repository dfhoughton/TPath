package TPath::Selector::Test::AxisWildcard;

# ABSTRACT: handles C</ancestor::*> or C</preceding::*> where this is not the first step in the path, or C<ancestor::*>, etc.

use feature 'state';
use Moose;
use TPath::Test::Node::True;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

sub BUILD {
	my $self = shift;
	state $nt = TPath::Test::Node::True->new;
	$self->_node_test($nt);
}

__PACKAGE__->meta->make_immutable;

1;
