package TPath::Selector::Test;

# ABSTRACT: role of selectors that apply some test to a node to select it

=head1 DESCRIPTION

A L<TPath::Selector> that holds a list of L<TPath::Predicate>s.

=cut

use Moose::Role;
use TPath::TypeConstraints;
use TPath::Test::Node::Complement;

=head1 ROLES

L<TPath::Selector>

=cut

with 'TPath::Selector';

=attr predicates

Auto-deref'ed list of L<TPath::Predicate> objects that filter anything selected
by this selector.

=cut

has predicates => (
    is         => 'ro',
    isa        => 'ArrayRef[TPath::Predicate]',
    default    => sub { [] },
    auto_deref => 1
);

=attr axis

The axis on which nodes are sought; C<child> by default.

=cut

has axis =>
  ( is => 'ro', isa => 'Axis', writer => '_axis', default => sub { 'child' } );

# axis translated into a forester method name
has faxis => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    default =>
      sub { my $self = shift; ( my $v = $self->axis ) =~ tr/-/_/; "axis_$v" }
);

=attr node_test

The test that is applied to select candidates on an axis.

=cut

has node_test =>
  ( is => 'ro', isa => 'TPath::Test::Node', writer => '_node_test' );

sub _invert {
    my $self = shift;
    $self->_node_test(
        TPath::Test::Node::Complement->new( nt => $self->node_test ) );
}

=method candidates

Expects a node and an index and returns nodes selected before filtering by predicates.

=cut

sub candidates {
    my ( $self, $n, $i ) = @_;
    my $axis = $self->faxis;
    $i->f->$axis( $n, $self->node_test, $i );
}

# implements method required by TPath::Selector
sub select {
    my ( $self, $n, $i ) = @_;
    my @candidates = $self->candidates( $n, $i );
    for my $p ( $self->predicates ) {
        last unless @candidates;
        @candidates = $p->filter( $i, \@candidates );
    }
    return @candidates;
}

1;
