package TPath::Selector::Test;

# ABSTRACT: role of selectors that apply some test to a node to select it

=head1 DESCRIPTION

A L<TPath::Selector> that holds a list of L<TPath::Predicate>s.

=cut

use v5.10;
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
  ( is => 'ro', isa => 'Axis', writer => '_axis', default => 'child' );

=attr first_sensitive

Whether this this test may use a different axis depending on whether it is the first
step in a path.

=cut

has first_sensitive => ( is => 'ro', isa => 'Bool', default => 0 );

# axis translated into a forester method name
has faxis => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    default =>
      sub { my $self = shift; ( my $v = $self->axis ) =~ tr/-/_/; "axis_$v" }
);

=attr is_inverted

Whether the test corresponds to a complement selector.

=cut

has is_inverted =>
  ( is => 'ro', isa => 'Bool', default => 0, writer => '_mark_inverted' );

around 'to_string' => sub {
    my ( $orig, $self, @args ) = @_;
    my $s = $self->$orig(@args);
    for my $p ( @{ $self->predicates } ) {
        $s .= '[ ' . $p->to_string . ' ]';
    }
    return $s;
};

sub _stringify_match {
    my ( $self, $re ) = @_;

    # chop off the "(?-xism:" prefix and ")" suffix
    if ( $re =~ /^\Q(?-xism:\E/ ) {
        $re = substr $re, 8, length($re) - 9;
    }
    elsif ( $re =~ /^\Q(?^:\E/ ) {
        $re = substr $re, 4, length($re) - 5;
    }
    $re =~ s/~/~~/g;
    return "~$re~";
}

=attr node_test

The test that is applied to select candidates on an axis.

=cut

has node_test =>
  ( is => 'ro', isa => 'TPath::Test::Node', writer => '_node_test' );

sub _invert {
    my $self = shift;
    $self->_node_test(
        TPath::Test::Node::Complement->new( nt => $self->node_test ) );
    $self->_mark_inverted(1);
}

=method candidates

Expects an L<TPath::Context> and whether this is the first selector in its path
and returns nodes selected before filtering by predicates.

=cut

sub candidates {
    my ( $self, $ctx, $first ) = @_;
    my $axis = $self->_select_axis($first);
    return $ctx->i->f->$axis( $ctx, $self->node_test );
}

sub _select_axis {
    my ( $self, $first ) = @_;
    if ( $first && $self->first_sensitive ) {
        for ( $self->axis ) {
            when ('child')      { return 'axis_self' }
            when ('descendant') { return 'axis_descendant_or_self' }
        }
    }
    return $self->faxis;
}

# implements method required by TPath::Selector
sub select {
    my ( $self, $ctx, $first ) = @_;
    my @candidates = $self->candidates( $ctx, $first );
    for my $p ( $self->predicates ) {
        last unless @candidates;
        @candidates = $p->filter( \@candidates );
    }
    return @candidates;
}

1;
