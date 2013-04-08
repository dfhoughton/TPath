package TPath::Selector::Test::AxisTag;

# ABSTRACT: handles C</ancestor::foo> or C</preceding::foo> where this is not the first step in the path, or C<ancestor::foo>

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has tag => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Tag->new( tag => $self->tag ) );
}

sub to_string {
    my ( $self, $first ) = @_;
    my $s = $first ? '' : '/';
    $s .= $self->axis . '::';
    $s .= '^' if $self->is_inverted;
    $s .= $self->_stringify_label( $self->tag );
    return $s;
}

__PACKAGE__->meta->make_immutable;

1;
