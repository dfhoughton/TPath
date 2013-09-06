package TPath::Selector::Test::AxisWildcard;

# ABSTRACT: handles C</ancestor::*> or C</preceding::*> where this is not the first step in the path, or C<ancestor::*>, etc.

use v5.10;

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

sub to_string {
    my ( $self, $first ) = @_;
    my $s = $first ? '' : '/';
    $s .= $self->axis . '::';
    $s .= '*';
    return $s;
}

__PACKAGE__->meta->make_immutable;

1;
