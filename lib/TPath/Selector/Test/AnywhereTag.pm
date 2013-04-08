package TPath::Selector::Test::AnywhereTag;

# ABSTRACT: handles C<//foo> expression

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test';

has tag => ( is => 'ro', isa => 'Str', required => 1 );

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;
    $class->$orig(
        %args,
        first_sensitive => 1,
        axis            => 'descendant',
    );
};

sub BUILD {
    my $self = shift;
    my $nt = TPath::Test::Node::Tag->new( tag => $self->tag );
    $self->_node_test($nt);
}

sub to_string {
    my $self = shift;
    return
        '//'
      . ( $self->is_inverted ? '^' : '' )
      . $self->_stringify_label( $self->tag );
}

__PACKAGE__->meta->make_immutable;

1;
