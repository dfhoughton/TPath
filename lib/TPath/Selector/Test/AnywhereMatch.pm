package TPath::Selector::Test::AnywhereMatch;

# ABSTRACT: handles C<//~foo~> expression

use Moose;
use TPath::Test::Node::Match;
use namespace::autoclean;

=head1 ROLES

L<TPath::Selector::Test>

=cut

with 'TPath::Selector::Test::Match';

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
    my $nt = TPath::Test::Node::Match->new( rx => $self->rx );
    $self->_node_test($nt);
}

sub to_string {
    my $self = shift;
    return
        '//'
      . ( $self->is_inverted ? '^' : '' )
      . $self->_stringify_match( $self->val );
}

__PACKAGE__->meta->make_immutable;

1;
