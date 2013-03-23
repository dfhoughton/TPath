package TPath::Selector::Test::ChildTag;

# ABSTRACT: handles C</foo> where this is not the first step in the path, or C<child::foo>

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

__PACKAGE__->meta->make_immutable;

1;
