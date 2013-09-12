package TPath::Selector::Test::AxisMatch;

# ABSTRACT: handles C</ancestor::~foo~> or C</preceding::~foo~> where this is not the first step in the path, or C<ancestor::~foo~>, etc.

use Moose;
use TPath::Test::Node::Match;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test::Match';

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Match->new( rx => $self->rx ) );
}

sub to_string {
    my ( $self, $first ) = @_;
    my $s = $first ? '' : '/';
    $s .= $self->axis . '::';
    $s .= '^' if $self->is_inverted;
    $s .= $self->_stringify_match( $self->val );
    return $s;
}

__PACKAGE__->meta->make_immutable;

1;
